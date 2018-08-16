/**
 * NoobHub node.js server (modified by Xavier Harris)
 * Opensource multiplayer and network messaging for CoronaSDK, Moai, Gideros & LÖVE
 *
 * @usage
 * $ nodejs node.js
 *
 * @authors
 * Igor Korsakov
 * Sergii Tsegelnyk
 *
 * @license WTFPL
 *
 * https://github.com/Overtorment/NoobHub
 *
 **/

// function for changing server status icon
function refreshServerPopulation() {
	var population = 0;
	for (var channel in sockets) {
		population += Object.keys(sockets[channel]).length;
	}
	module.exports.onPopulationChange(population);
}

var noobserver = require('net').createServer()
var sockets = {}  // this is where we store all current client socket connections
var leaders = {}
var saved_messages = {};
var cfg = {
	port: process.env.PORT || 8080,
  buffer_size: 1024 * 16, // buffer allocated per each socket client
  verbose: true // set to true to capture lots of debug info
}
var _log = function () {
	if (cfg.verbose) console.log.apply(console, arguments)
}

var jsonFormat = function(data) {
	return '__JSON__START__' + JSON.stringify(data) + '__JSON__END__';
}

// black magic
process.on('uncaughtException', function (err) {
  //_log('Exception: ' + err) // TODO: think we should terminate it on such exception
})

noobserver.on('connection', function (socket) {
	socket.setNoDelay(true)
	socket.setKeepAlive(true, 300 * 1000)
	socket.isConnected = true
	socket.connectionId = socket.remoteAddress + '-' + socket.remotePort // unique, used to trim out from sockets hashmap when closing socket
	socket.buffer = new Buffer(cfg.buffer_size)
	socket.buffer.len = 0 // due to Buffer's nature we have to keep track of buffer contents ourself

	//_log('+ ' + socket.connectionId)

	socket.on('data', function (dataRaw) { // dataRaw is an instance of Buffer as well
	if (dataRaw.length > (cfg.buffer_size - socket.buffer.len)) {
		//_log("Message doesn't fit the buffer. Adjust the buffer size in configuration")
		socket.buffer.len = 0 // trimming buffer
		return false
	}

	socket.buffer.len += dataRaw.copy(socket.buffer, socket.buffer.len) // keeping track of how much data we have in buffer

	var start
	var end
	var str = socket.buffer.slice(0, socket.buffer.len).toString()

	if ((start = str.indexOf('__SUBSCRIBE__')) !== -1 && (end = str.indexOf('__ENDSUBSCRIBE__')) !== -1) {
		// if socket was on another channel delete the old reference
		if (socket.channel && sockets[socket.channel] && sockets[socket.channel][socket.connectionId]) {
			delete sockets[socket.channel][socket.connectionId]
		}
		socket.channel = str.substr(start + 13, end - (start + 13))
		//_log(socket.connectionId + ' is in ' + socket.channel)
		str = str.substr(end + 16)  // cut the message and remove the precedant part of the buffer since it can't be processed
		socket.buffer.len = socket.buffer.write(str, 0)
		sockets[socket.channel] = sockets[socket.channel] || {} // hashmap of sockets  subscribed to the same channel
		sockets[socket.channel][ socket.connectionId ] = socket

		// send client their id
		socket.write(jsonFormat({
			type:'netevent',
			event:'getID',
			info:{
				id:socket.connectionId,
				is_leader:(leaders[socket.channel]==null)
			}
		}));

		// send them saved messages >:)
		if (saved_messages[socket.channel]) {
			for (var msg of saved_messages[socket.channel]) {
				socket.write(msg);
			}
		}
	
		var subscribers = Object.keys(sockets[socket.channel]);
		for (var i = 0, l = subscribers.length; i < l; i++) {
			if (subscribers[i] != socket.connectionId) {
				sockets[socket.channel][ subscribers[i] ].isConnected && sockets[socket.channel][ subscribers[i] ].write(jsonFormat({
					type:'netevent',
					event:'client.connect',
					clientid:socket.connectionId
				}))
			}

			// give the first person 'leadership' if there isn't a leader
			if (!leaders[socket.channel]) {
				leaders[socket.channel] = socket.connectionId;
				socket.write(jsonFormat({	
		            type:'netevent',
		            event:'set.leader',
		            info:socket.connectionId
				}));
			}

		} // writing this message to all sockets with the same channel 
	}

  	refreshServerPopulation();
	var timeToExit = true
	do {  // this is for a case when several messages arrived in buffer
		if ((start = str.indexOf('__JSON__START__')) !== -1 && (end = str.indexOf('__JSON__END__')) !== -1) {
			var json = str.substr(start + 15, end - (start + 15))

			// save this message for future clients?
			if (json.includes('"save"')) {
				if (!saved_messages[socket.channel])
					saved_messages[socket.channel] = [];
				saved_messages[socket.channel].push(str);
			}

			str = str.substr(end + 13)  // cut the message and remove the precedant part of the buffer since it can't be processed
		socket.buffer.len = socket.buffer.write(str, 0)

		var subscribers = Object.keys(sockets[socket.channel])
		for (var i = 0, l = subscribers.length; i < l; i++) {
			sockets[socket.channel][ subscribers[i] ].isConnected && sockets[socket.channel][ subscribers[i] ].write('__JSON__START__' + json + '__JSON__END__')
			} // writing this message to all sockets with the same channel
			timeToExit = false
			} else { timeToExit = true } // if no json data found in buffer - then it is time to exit this loop
		} while (!timeToExit)
	}) // end of  socket.on 'data'

	socket.on('error', function () { return _destroySocket(socket) })
	socket.on('close', function () { return _destroySocket(socket) })
	}) //  end of server.on 'connection'

var _destroySocket = function (socket) {
	if (!socket.channel || !sockets[socket.channel] || !sockets[socket.channel][socket.connectionId]) return
		sockets[socket.channel][socket.connectionId].isConnected = false
	sockets[socket.channel][socket.connectionId].destroy()
	sockets[socket.channel][socket.connectionId].buffer = null
	delete sockets[socket.channel][socket.connectionId].buffer
	delete sockets[socket.channel][socket.connectionId]
	_log('- ' + socket.connectionId + ' (' + socket.channel + ')')
	if (leaders[socket.channel] == socket.connectionId) {
		let keys = Object.keys(sockets[socket.channel]);

		if (keys.length > 0) {
			let random_id = keys[Math.floor(Math.random()*keys.length)];

			sockets[socket.channel][random_id].write(jsonFormat({
				type:'netevent',
				event:'set.leader',
				info:random_id
			}));
			leaders[socket.channel] = random_id;
		} else {
			// no one left :'(
			delete leaders[socket.channel];
			delete saved_messages[socket.channel];
			_log(socket.channel,"is empty");
		}
	}

	if (Object.keys(sockets[socket.channel]).length === 0) {
		delete sockets[socket.channel]
		//_log(socket.channel + ' is empty')
	}
	refreshServerPopulation();
}

module.exports.address = null;

module.exports.start = function(cb){
	if (!noobserver.listening) {
		noobserver.listen(cfg.port,  function () {
			_log('NoobHub on ', noobserver.address().address + noobserver.address().port);
			module.exports.address = noobserver.address().address + noobserver.address().port;
			if (cb) cb(noobserver.address().address + noobserver.address().port);
		});
	}
}

module.exports.stop = function(cb){
	if (noobserver.listening) {
		noobserver.close(function(){
			module.exports.address = null;
			if (cb) cb(true);
		});
	} else
		if (cb) cb(false);
}

module.exports.setLogFunction = function(fn) {
	_log = fn;
}

module.exports.onPopulationChange = function() {}
