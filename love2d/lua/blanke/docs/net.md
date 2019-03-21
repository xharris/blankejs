**Net** allows for communication with a server and other clients connected to that server. It's important to note that when using multiplayer functions, it is not necessary to use all the functions available here. 


# Properties

```
str address							'localhost' / 'xxx.xxx.xxx.xxx' / 'http://...'
num port							8000
num id 								-- unique client id assigned to the player 
bool is_leader						-- only true for one person on server and moves to another if that person leaves
bool is_connected
```

# Methods

```
join([address], [port])				-- address = "localhost", port = 12345
disconnect()

send(data) send object to other clients 
sendPersistent(data) 				-- send data. saved server side and sent to new players that join later
event('name', data)					-- send event with name and data

getPopulation()						-- get number of clients connected (including self)
draw([classname])					-- draw objects synced through network, or just a certain class
addObject(obj)						-- add an object to be synced with other clients
```

# Events and Callbacks

## Net.on('callback', fn)

Callbacks

```
ready					-- current player sucessfully connects to the server
connect					-- another player has connected
disconnect				-- another player has disconnected
receive(info)			-- received object 'data'
event(event,info)
```

## Event types
```
client.connect
client.disconnect
broadcast
object.add			-- another client used Net.addObject()
object.update
object.sync			
set.leader			-- info = clientid of current leader
room.change			-- *not ready yet*
```

## Structure of 'data' object

```
{
	clientid = who sent the data
	room = id of room client is in
	type = 'netevent' or nothing
	event = string if this is a netevent
	info = {...}
}
```