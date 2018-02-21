require 'class'
grease = require 'grease'
require 'Util'
require 'json'
local uuid = require 'uuid'
local Debug = require 'Debug'

Debug.setFontSize(10)
Debug.setMargin(5)

-- BlankE Net server
Net = {    
    is_init = false,
    server = nil,
    
    onReceive = nil,    
    onConnect = nil,    
    onDisconnect = nil, 
    
    address = "localhost",
    port = 12345,
    bytes = 0,

    _clients = {},
    _rooms = {},   

    id = nil,

    init = function(address, port)
        Net.address = ifndef(address, "localhost") 
        Net.port = ifndef(port, Net.port) 
        Net.is_init = true

        Debug.log("networking initialized")
    end,
    
    update = function(dt,override)
        override = ifndef(override, true)

        if Net.is_init then
            if Net.server then Net.server:update(dt) end
        end
    end,

    -- returns "Server" object
    host = function()
        if not Net.is_init then
            Net.init(Net.address, Net.port)
        end      
        Net.server = grease.udpServer()

        Net.server.callbacks.connect = Net._onConnect
        Net.server.callbacks.disconnect = Net._onDisconnect
        Net.server.callbacks.recv = Net._onReceive

        Net.server.handshake = "blanke_net"
        
        Net.server:listen(Net.port)

        Debug.log('hosting ' .. Net.address .. ':' .. Net.port)
        -- room_create() -- default room
    end,
    
    _onConnect = function(clientid) 
        Debug.log('+ ' .. clientid)
        Net.send({
            type='netevent',
            event='client.connect',
            info=clientid
        })
        Net.send({
            type='netevent',
            event='getID',
            info=clientid
        }, clientid)
        Net._clients[clientid] = {}
    end,
    
    _onDisconnect = function(clientid) 
        Debug.log('- ' .. clientid)

        for id, objects in pairs(Net._clients) do
            Net._clients[id] = nil
        end

        Net.send({
            type='netevent',
            event='client.disconnect',
            info=clientid
        })
    end,

    _onReceive = function(data, id)
        -- calculate # of bytes used
        Net.bytes = Net.bytes + bytes(data)

        if data:starts('{') then
            data = json.decode(data)
        elseif data:starts('"') then
            data = data:sub(2,-2)
        end

        if type(data) == "string" and data:ends('\n') then
            data = data:gsub('\n','')
        end

        if type(data) == "string" and data:ends('-') then
            Net._onDisconnect(data:sub(1,-2))
            return
        end

        if type(data) == "string" and data:ends('+') then
            Net._onConnect(data:sub(1,-2))
            return
        end

        if data.type and data.type == 'netevent' then
            Debug.log(data.event)
            Net.send(data)
        end
    end,

    send = function(data, clientid) 
        data = json.encode(data)
        Net.server:send(data, clientid)
        return Net
    end
}

function love.load()
    Net.host()
end

function love.update(dt)
    Net.update(dt)
end

function love.draw()
    Debug.draw()

    love.graphics.setColor(255,0,0,255)
    love.graphics.setFont(Debug._font)

    local byte_str = tostring(Net.bytes)
    for b, term in ipairs({'B','KB','MB','GB'}) do
        local floor = (math.pow(1000, b-1)-1)
        if Net.bytes > floor then
            byte_str = tostring(math.round(Net.bytes / floor), 0) .. " " .. term
        end
    end

    love.graphics.printf("ESTIMATES\ndata in: "..byte_str, 0, Debug.margin, love.graphics:getWidth()-Debug.margin, "right") 
end

function bytes(str)
    bit_total = 0
    str_len = string.len(str)

    for s = 1, str_len do
        local char = str:byte(s,s)

        bit_total = bit_total + 1
    end

    return bit_total

    --[[
        function getUTF8Length(str) {
      var len = 0;
      for (var i = 0; i < str.length; i++) {
        var code = str.charCodeAt(i);
        if (code <= 0x7f) {
          len += 1;
        } else if (code <= 0x7ff) {
          len += 2;
        } else if (code >= 0xd800 && code <= 0xdfff) {
          // Surrogate pair: These take 4 bytes in UTF-8 and 2 chars in UCS-2
          // (Assume next char is the other [valid] half and just skip it)
          len += 4; i++;
        } else if (code < 0xffff) {
          len += 3;
        } else {
          len += 4;
        }
      }
      return len;
    }
    ]]
end