Entity.addInitFn(function(self, args)
    if args.net then
        Net.sync(self)
    end
end)

Net = nil
do
    local socket = require "socket"
    require "plugins.xhh-net.noobhub"
    local client
    local leader = false

    local sendData = function(data)
        if client then 
            client:publish({
                message = {
                    type="data",
                    timestamp = love.timer.getTime(),
                    data=data,
                    room=Net.room
                }
            })
        end
    end 

    local sendNetEvent = function(event, data)
        if client then 
            client:publish({
                message = {
                    type="netevent",
                    timestamp = love.timer.getTime(),
                    event=event,
                    data=data,
                    room=Net.room
                }
            })
        end
    end

    local onReceive = function(data)
        if data.type == "netevent" then 
            if data.event == "getID" then 
                Net.id = data.id
                leader = data.is_leader
            end
            if data.event == "set.leader" then 
                leader = true
            end
            if data.event == "client.connect" and data.clientid ~= Net.id then 
                Signal.emit('net.connect', data.clientid)
            end
            if data.event == "client.disconnect" then 
                Signal.emit('net.disconnect', data.clientid)
            end
        elseif data.type == "data" then
            Signal.emit('net.data', data.data, data)
        end
    end

    local onFail = function()

    end

    Signal.on('update', function(dt)
        if client then client:enterFrame() end
    end)

    Net = {
        address='localhost',
        port=8080,
        room=1,
        ip='',
        client=nil,
        connect = function(address,port)
            Net.address = address or Net.address
            Net.port = port or Net.port
            client = noobhub.new({ server=Net.address, port=Net.port })
            if client then 
                client:subscribe({
                    channel = "room"..tostring(Net.room),
                    callback = onReceive,
                    cb_reconnect = onFail
                })
            else 
                print("failed connecting to "..Net.address..":"..Net.port)
                onFail()
            end
        end,
        disconnect = function()
            if client then 
                client:unsubscribe()
                client = nil
                leader = false
            end
        end,
        connected = function() return client ~= nil end,
        send = function(data)
            sendData(data)
        end,
        on = function(event, fn)
            Signal.on('net.'..event, fn)
        end,
        sync = function(obj) 

        end
    }

    local s = socket.udp()
    s:setpeername("74.125.115.104",80)
    local ip, _ = s:getsockname()
    Net.ip = ip
end