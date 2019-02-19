local TYPE_FUNCTION = '_type.function'

Net = {
    obj_update_rate = 0, -- m/s
    
    logging = false,
    is_init = false,
    is_leader = false,
    current_leader = nil,   -- clientid of current leader
    wants_leader = false,
    client = nil,
    clients = {},           -- list of clients connected
    
    onReceive = nil,    
    onConnect = nil,    
    onDisconnect = nil, 
    
    address = "localhost",
    port = 8080,
    room = 1,

    _objects = {_orphans={}},          -- objects sync from other clients _objects = {'client12' = {object1, object2, ...}}
    _local_objects = {},    -- objects added by this client

    id = nil,
    _timer = 0,

    init = function(address, port)
        if Net.is_init then return end

        socket = require "socket"

        local s = socket.udp()
        s:setpeername("74.125.115.104",80)
        local ip, _ = s:getsockname()
        Net.ip = ip

        Net.address = ifndef(address, Net.address) 
        Net.port = ifndef(port, Net.port)     
        Net.is_init = true

        Net._timer = Timer():every(Net.updateObjects, 1):start()

        return Net
    end,
    
    -- returns "Client" object
    join = function(address, port) 
        if Net.client or Net.is_connected then return end
        if not Net.is_init then
            Net.init(address, port)
        end

        Net.log("connecting to",Net.address,Net.port)
        Net.client = noobhub.new({ server=Net.address; port=Net.port; })
        if Net.client then
            Net.is_connected = true
            Net.client:subscribe({
                channel = "room"..tostring(Net.room),
                callback = Net._onReceive,
                cb_reconnect = function() return Net._onFail(address, port) end
            })
        else
            Net.log("could not connect to "..Net.address..":"..Net.port)
            Net._onFail(address, port)
        end

        return Net
    end,

    update = function() 
        if Net.wants_leader then
            Net.setLeader()
        end
        if Net.client then Net.client:enterFrame() end
    end,

    disconnect = function()
        if not Net.client or not Net.is_connected then return end

        Net.send({
            type='netevent',
            event='client.disconnect',
            info=clientid
        })

        Net.removeLocalObjects()

        Net.client:unsubscribe()
        Net.is_init = false
        Net.is_connected = false
        Net.client = nil

        Net.removeClientObjects()

        Net.log("disconnected")

        return Net
    end,

    log = function(...)
        if Net.logging then Debug.log(...) end
    end,

    on = function(callback, fn)
        local signal_names = {
            ready='_net.ready',
            connect='_net.connect',
            disconnect='_net.disconnect',
            receive='_net.receive',
            event='_net.event'
        }
        local special_names = {
            fail='onFail'
        }
        if signal_names[callback] then
            Signal.on(signal_names[callback], fn)
        end
        if special_names[callback] then
            Net[special_names[callback]] = fn
        end
    end,

    _onReady = function()
        Signal.emit('_net.ready')
        -- request an object sync from other clients
        Net.send({
            type='netevent',
            event='client.connect',
            info=Net.id
        })
        Net.send({
            type="netevent",
            event="object.sync",
            info={
                new_client=Net.id
            }
        })
    end,
    
    _onFail = function(...)
        if Net.onFail and Net.onFail() then
            Net.join(...)
        end
        return false
    end,

    _onConnect = function(clientid)
        --Net.log('+ '..clientid)
        Net.clients[clientid] = true
        Signal.emit('_net.connect', clientid)
    end,
    
    _onDisconnect = function(clientid) 
        --Net.log('- '..clientid)
        Net.clients[clientid] = nil
        Signal.emit('_net.disconnect', clientid)
        Net.removeClientObjects(clientid) 
    end,
    
    _onReceive = function(data)
        if data.type and data.type == 'netevent' then
            --Net.log(data.event)
            -- get assigned client id
            if data.event == 'getID' then
                Net.id = data.info.id
                Net.is_leader = data.info.is_leader
                Net.log('connected to '..Net.address..':'..Net.port..' as '..Net.id..'!')
                Net._onReady()
            end

            if data.event == 'client.connect' and data.clientid == Net.id then
                Net._onConnect(data.clientid)
            end

            if data.event == 'client.disconnect' and data.clientid ~= Net.id  then
                Net._onDisconnect(data.clientid)
            end

            if not data.room then data.room = Net.room end
            if data.room == Net.room then
                Net._onEvent(data)
            end

            -- another entity changed their room
            if data.event == 'room.change' and data.clientid ~= Net.id and data.room ~= Net.room then
                Net.removeClientObjects(data.clientid) 
            end

            -- send to all clients
            if data.event == 'broadcast' then
                -- print('ALL:',data.info)
            end
        end

        Signal.emit('_net.receive')
    end,

    _objApplyValues = function(obj, values)
        if values then
            for var, val in pairs(values) do
                obj[var] = val
            end
        end
    end,

    _onEvent = function(data)
        -- new object added from diff client
        if data.event == 'object.add' and data.clientid ~= Net.id then
            local obj = data.info.object
            local clientid = data.clientid

            Net._objects[clientid] = ifndef(Net._objects[clientid], {})
            if not Net._objects[clientid][obj.net_uuid] then

                _G[obj.classname]._init_properties = {
                    net_uuid = obj.net_uuid,
                    net_owner_id = clientid,
                    net_object = true,
                    reapply_values = true
                }

                Net._prepareNetObject(_G[obj.classname]._init_properties, true)
                _G[obj.classname]._init_properties.net_owner_id = clientid
                Net._objApplyValues(_G[obj.classname]._init_properties, obj.values)

                Net._objects[clientid][obj.net_uuid] = _G[obj.classname]()
                local obj_ref = Net._objects[clientid][obj.net_uuid]

                if obj_ref.reapply_values then Net._objApplyValues(obj_ref, obj.values) end
                
                if obj.values then
                    for var, val in pairs(obj.values) do
                        if obj_ref.onNetUpdate then obj_ref:onNetUpdate(var, val) end
                    end
                end
            end
        end

        -- update net entity
        if data.event == 'object.update' and data.clientid ~= Net.id then
            local obj_list
            if data.info.net_owner_id == Net.id then
                obj_list = Net._local_objects
            else
                obj_list = Net._objects[data.info.net_owner_id]
            end

            if obj_list then
                local obj = obj_list[data.info.net_uuid]
                if obj then
                    for var, val in pairs(data.info.values) do
                        if var == '_functions' then
                            for f, info in ipairs(val) do
                                local fn_name = info[1]
                                obj.net_fn_disabled[fn_name] = true
                                obj[fn_name](obj,unpack(info,2,#info))
                                obj.net_fn_disabled[fn_name] = false
                            end
                        else
                            obj[var] = val
                        end
                        if obj.onNetUpdate and obj.net_object then obj:onNetUpdate(var, val) end
                    end
                end
            end
        end

        -- send net object data to other clients
        if data.event == 'object.sync' and data.info.new_client ~= Net.id then
            Net.sendSyncObjects()
        end

        -- a new leader has been selected
        if data.event == 'set.leader' then
            Net.current_leader = data.info
            if Net.current_leader == Net.id then
                Net.is_leader = true
            else
                Net.is_leader = false
                -- move any orphans into leader's array
                for o, obj in ipairs(Net._objects._orphans) do
                    Net._objects[Net.current_leader][obj.net_uuid] = obj
                    obj.net_owner_id = Net.current_leader
                end
                Net._objects._orphans = {}
            end
        end
        
        Signal.emit('_net.event', data)
    end,

    sendPersistent = function(in_data) 
        if Net.is_leader then
            in_data.save = true
            Net.send(in_data)
        end 
        return Net
    end,

    send = function(in_data) 
        if in_data.type == 'netevent' then
            in_data.clientid = Net.id
            in_data.room = Net.room
        end
        if Net.client then Net.client:publish({message=in_data}) end
        return Net
    end,
    
    event = function(name, in_data)
        Net.send({
            type='netevent',
            event=name,
            info=in_data
        })
        return Net
    end,

    setRoom = function(num)
        Net.room = num
        Net.send({
            type='netevent',
            event='room.change'
        })
        Net.removeClientObjects()
    end,

    getObjects = function(classname, id)
        local ret_objects = {}
        for clientid, objects in pairs(Net._objects) do
            if not id or (id and clientid == id) then
                ret_objects[clientid] = {}
                for o, obj in pairs(objects) do
                    if not classname or (classname and obj.classname == classname) then
                        table.insert(ret_objects[clientid], obj)
                    end
                end
            end
        end
        return ret_objects
    end,

    removeClientObjects = function(clientid) 
        local removable = {}
        if not clientid then
            removable = Net._objects
        else
            removable[clientid] = Net._objects[clientid]
        end

        for id, objects in pairs(removable) do
            for uuid, obj in pairs(objects) do
                if Net.is_connected and obj.keep_on_disconnect then
                    -- transfer objects into current leaders array
                    if Net.is_leader then
                        obj.net_object = false
                        Net.addObject(obj)
                    elseif Net._objects[Net.current_leader] then
                        table.insert(Net._objects[Net.current_leader], obj)
                    else
                        -- leader hasn't been chosen yet, make them orphans for now D:
                        table.insert(Net._objects['_orphans'], obj)
                        obj.net_owner_id = '_orphans'
                    end
                else
                    obj:destroy()
                end
            end
            if table.len(Net._objects[id]) == 0 then
                Net._objects[id] = nil
            end
        end
    end,

    removeLocalObjects = function()
        for net_uuid, obj in pairs(Net._local_objects) do
            obj:destroy()
        end
        Net._local_objects = {}
    end,

    -- old: object transfered from a disconnected client
    _prepareNetObject = function(obj, old)
        if not old then obj.net_uuid = uuid() end

        obj.net_var_old = {}
        obj.net_functions = {}
        obj.net_fn_disabled = {}

        if not old and not obj.net_object then
            obj.net_owner_id = Net.id
        end

        obj.netSync = function(self, ...)
            if not Net.is_connected then return end
            vars = {...}

            update_values = {_functions={}}
            if Net.is_connected then
                function isFunction(var_name)
                    if self.net_functions[var_name] == nil then
                        self.net_functions[var_name] = (type(self[var_name]) == 'function') 
                    end
                    return self.net_functions[var_name]
                end

                function hasVarChanged(var_name)
                    if self.net_var_old[var_name] ~= nil and
                       self.net_var_old[var_name] == self[var_name]
                    then
                        return false
                    end
                    self.net_var_old[var_name] = self[var_name]
                    return true
                end

                -- update specific vars
                for v, var in ipairs(vars) do
                    if var and self[var] ~= nil then
                        if isFunction(var) then
                            if not self.net_fn_disabled[var] then
                                table.insert(update_values._functions,{...})
                            end
                        elseif hasVarChanged(var) then
                            update_values[var] = self[var]
                        end
                    end
                end
                -- update all
                if #vars == 0 then
                    for v, var in ipairs(self.net_sync_vars) do
                        if hasVarChanged(var) then 
                            update_values[var] = self[var]
                        end
                    end
                end
                -- send collected vars
                if Net.is_connected and table.len(update_values) > 0 then
                    Net.send{
                        type="netevent",
                        event="object.update",
                        info={
                            net_uuid=self.net_uuid,
                            net_owner_id=self.net_owner_id,
                            values=update_values
                        }
                    }
                end
            end
        end
    end,

    -- old: object transfered from a disconnected client
    addObject = function(obj, old)
        Net._prepareNetObject(obj, old)
        if obj.net_object then return end

        --notify the other server clients
        if not old then
            Net.send({
                type='netevent',
                event='object.add',
                info={
                    object = {net_owner_id=Net.id, net_uuid=obj.net_uuid, classname=obj.classname}
                }
            })
        end
        Net._local_objects[obj.net_uuid] = obj    

        obj:netSync()
        if obj.onNetAdd and not old then obj:onNetAdd() end

        return Net
    end,

    once = function(fn)
        if Net.is_leader then fn() end
        return Net
    end,

    sendSyncObjects = function()
        for net_uuid, obj in pairs(Net._local_objects) do
            Net.send({
                type='netevent',
                event='object.add',
                info={
                    object = {net_uuid=obj.net_uuid, classname=obj.classname, values=obj.net_var_old}
                }
            })
            obj:netSync()
            if obj.onNetAdd then obj:onNetAdd() end
        end
    end,

    updateObjects = function()
        for net_uuid, obj in pairs(Net._local_objects) do
            obj:netSync()
            if obj.onNetSyncTimer then
                obj:onNetSyncTimer()
            end
        end
    end,

    getClients = function()
        return table.keys(Net.clients)
    end,
    
    getPopulation = function(room)
        if room then
            -- get population from different room
        else
            return table.len(Net._objects) -- doesn't need a +1 (for self) since there's the _orphans table
        end
    end,

    save = function(data)

    end,

    load = function(data)

    end,

    draw = function(classname)
        for clientid, objects in pairs(Net._objects) do
            for o, obj in pairs(objects) do
                if classname then
                    if obj.classname == classname then
                        obj:draw()
                    end
                else
                    obj:draw()
                end
            end
        end
        return Net
    end
}

return Net