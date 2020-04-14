-- @global
NO_STATE = '_'

local iterate
local all_entities = {}
-- sys vars
local systems, system_ids
local system_effect, system_entity
local sys_add
local system_callback_count
-- component vars
local component_defaults
local component_type
-- entity vars
local entity_defaults, entity_functions
-- world vars
local sys_callback
local state_callback, check_obj_state
local stray_entities, entity_sys_count, entity_state, last_world_state, world_state
local process_system
local world_add
local type_list, type_add, type_remove
-- state vars
local states

iterate = function(t, fn) -- fn(): return true to remove an object
    local len = #t
    local offset = 0
    for o = 1, len do
        local obj = t[o]
        if obj then 
            if fn(obj, o) == true then
                offset = offset + 1 
            else 
                t[o] = nil
                t[o - offset] = obj
            end
        end
    end
end

iterate_entities = function(t, fn) -- fn(): return true to remove an object
    local len = #t
    local offset = 0
    local resort = false
    for o, uuid in ipairs(t) do
        local uuid = t[o]
        local obj = all_entities[uuid]
        if obj then 
            if obj.destroyed then 
                offset = offset + 1
                type_remove(obj)
            else
                if fn(obj, o) == true then
                    offset = offset + 1 
                else 
                    t[o] = nil
                    t[o - offset] = obj.uuid
                    if obj.z == nil then obj.z = 0 end
                    -- sort later?
                    if obj._last_z ~= obj.z then
                        resort = true
                        obj._last_z = obj.z
                    end
                end
            end
        end
    end
    return resort
end

systems = {} -- { sys_id: { entity:{ uuid }, component:{ name }, callback:{ name:fn }, prop:{ k:v } } }
system_ids = {} -- { sys_id1, sys_id2 }
system_entity = {} -- { sys_id: { ent_uuid:t/nil/'new' } }
system_type = {} -- { sys_id: type_str }
system_callback_count = {} -- { callback_name: # }
callback_entity_count = {} -- { callback_name: # }

-- @global
destroy = function(obj)
    if obj and not obj.destroyed then 
        obj.destroyed = true
        if obj._children then 
            for k, v in ipairs(obj._children) do 
                destroy(v)
            end
        end
    end
end

sys_add = function(sys_id, obj)
    local sys_ref = systems[sys_id]
    if not system_entity[sys_id] then system_entity[sys_id] = {} end 
    obj.is_entity = true
    
    if not system_entity[sys_id][obj.uuid] then 
        entity_sys_count[obj.uuid] = entity_sys_count[obj.uuid] + 1
        system_entity[sys_id][obj.uuid] = 'new'
        table.insert(sys_ref.entity, obj.uuid)
    end
    -- obj was recently added
    if system_entity[sys_id][obj.uuid] == 'new' then
        for cb_name, _ in pairs(sys_ref.callback) do 
            if not callback_entity_count[cb_name] then callback_entity_count[cb_name] = 1 else 
            callback_entity_count[cb_name] = callback_entity_count[cb_name] + 1 end
        end

        system_entity[sys_id][obj.uuid] = true
    end
end

-- @global
System = callable {
    __call = function(_, args)
        local sys_id = uuid()
    
        args = args or {}
        if args.template and args.template.type then
            args.type = args.template.type
        end

        systems[sys_id] = { uuid=sys_id, entity={}, type=(args.type or nil), component={}, callback={}, prop={ index=1 } }
        table.insert(system_ids, sys_id)

        local sys_ref = systems[sys_id]
        -- parse args
        for c = 1, #args do 
            -- required components
            table.insert(sys_ref.component, args[c])
        end
        for name, v in pairs(args) do 
            if type(v) == 'function' then
                -- store callback
                sys_ref.callback[name] = v
                if not system_callback_count[name] then 
                    system_callback_count[name] = 1 
                else 
                    system_callback_count[name] = system_callback_count[name] + 1
                end
            else 
                -- store system property
                sys_ref.prop[name] = v
            end
        end
        if args.type then 
            system_type[sys_id] = args.type
        end
        
        table.sort(system_ids, function(a, b) 
            return systems[a].prop.index < systems[b].prop.index
        end)

        if args.type then 
            return Spawner(args.type, args.template)
        end
    end,
    -- see if the object fits into any systems
    add = function(obj, system_id) 
        local sys_ref
        local found_a_system = false
        for _, sys_id in ipairs(system_ids) do 
            sys_ref = systems[sys_id]
            local this_system = false
            if obj.type and obj.type == system_type[sys_id] then 
                -- this system handles entities of this type
                sys_add(sys_id, obj)
                found_a_system = true
                this_system = true
            end
            for _, component in ipairs(sys_ref.component) do 
                if obj[component] ~= nil then 
                    -- this system handles entities with this component
                    sys_add(sys_id, obj)
                    found_a_system = true
                    this_system = true
                end
            end
            if this_system then 
                sys_callback(sys_ref, 'add', obj)
            end
        end
        return found_a_system
    end,
    remove = function(obj, sys_id)
        if not sys_id then
            -- remove object from all systems
            for _, sys_id in ipairs(system_ids) do 
                System.remove(obj, sys_id)
            end
        else
            local sys_ref = systems[sys_id]
            -- remove object from one system
            if system_entity[sys_id] and system_entity[sys_id][obj.uuid] then
                print('rem',obj.type) 
                sys_callback(sys_ref, 'remove', obj)                        
                entity_sys_count[obj.uuid] = entity_sys_count[obj.uuid] - 1
                system_entity[sys_id][obj.uuid] = nil
                if entity_sys_count[obj.uuid] == 0 then 
                    -- entity is no longer part of any system
                    table.insert(stray_entities, obj.uuid)
                end
            end
            
            for cb_name, _ in pairs(sys_ref.callback) do  
                if callback_entity_count[name] then
                        callback_entity_count[cb_name] = callback_entity_count[cb_name] - 1 
                end
            end
        end
    end,
    -- is the object in at least one system
    contains = function(obj)
        for _, sys_id in ipairs(system_ids) do
            if systems_entity[sys_id] and systems_entity[sys_id][obj.uuid] then 
                return true
            end
        end 
    end,
    callback_count = function(name)
        return system_callback_count[name] or 0
    end,
    callback_entity_count = function(name)
        return callback_entity_count[name] or 0
    end,
    stats = function(_type)
        local stats = {} 
        if _type == 'callback' then 
            for name, count in pairs(callback_entity_count) do 
                table.insert(stats, name..'='..count)
            end
        else 
            for _, sys_id in ipairs(system_ids) do 
                local sys_ref = systems[sys_id]
                table.insert(stats, (system_type[sys_id] or table.join(sys_ref.component, '-')) .. '=' .. #sys_ref.entity)
            end
            table.insert(stats, ('none=' .. #stray_entities))
        end
        return table.join(stats, ', ') 
    end
}

-- register defaults for a component
component_defaults = {} -- { name={ prop=value } }
component_type = {} -- { name=type(prop) }
--COMPONENT @global
Component = callable{
    __call = function(_, name, props)
        if type(name) == "table" then 
            -- add multiple components at once
            for name2, props2 in pairs(name) do
                Component(name2, props2)
            end
            return
        else 
            local comp_type = type(props)
            component_defaults[name] = copy(props)
            component_type[name] = comp_type
            -- add just the keys
            if comp_type == "table" and props[1] == nil then 
                for k, _ in pairs(props) do 
                    table.insert(component_defaults[name], k)
                end
            end
        end
    end,
    exists = function(name)
        return component_defaults[name] ~= nil
    end,
    use = function(entity, name)
        if component_defaults[name] ~= nil then 
            if component_type[name] == "table" then 
                if not entity[name] then entity[name] = {} end
                table.update(entity[name], component_defaults[name])
            else 
                entity[name] = component_defaults[name]
            end
        else 
            entity[name] = {}
        end
    end
}

--[[ -- remove this 'class'?
entity_defaults = {} -- { name={ prop=value } }
entity_functions = {} -- { entity_name={ fn_name=fn() } }
-- @global
Entity = callable{
    __call = function(_, name, props)
        -- store props as components
        entity_defaults[name] = {}
        for k,v in pairs(props) do 
            Component.use(entity_defaults[name], k)
        end
        return function(name, overrides)
            Entity.spawn(name, overrides)
        end
    end,
    spawn = function(name, overrides)
        local new_entity = {}
        if entity_defaults[name] then 
            table.update(new_entity, entity_defaults[name])
        end
        World.add(new_entity)
    end
}
]]

sys_callback = function(sys_ref, name, obj, ...)
    if sys_ref.callback[name] then 
        return sys_ref.callback[name](obj, ...)
    end
end

state_callback = function(name, ...)
    if states[world_state] and states[world_state][name] then 
        return states[world_state][name](...)
    end
end

check_obj_state = function(obj)
    return entity_state[obj.uuid] ~= nil and (
        obj.persistent == true or 
        entity_state[obj.uuid] == world_state or 
        entity_state[obj.uuid] == NO_STATE
    )
end

process_system = function(sys_id, cb_name, args, wrapper_fn)
    local sys_ref = systems[sys_id]
    if sys_ref.callback[cb_name] then
        -- iterate entities
        local resort = iterate_entities(sys_ref.entity, function(obj)
            local rem 
            if check_obj_state(obj) then
                if wrapper_fn then 
                    wrapper_fn(obj, function() 
                        if sys_callback(sys_ref, cb_name, obj, unpack(args)) then 
                            rem = true
                        end
                    end)
                else
                    if sys_callback(sys_ref, cb_name, obj, unpack(args)) then 
                        rem = true
                    end
                end
                if rem then 
                    print('rem',obj.type, sys_ref.type)
                    -- remove the obj from the system
                    System.remove(obj, sys_id)
                end
            else 
                rem = true 
            end
            return rem
        end)
        if resort then
            table.sort(sys_ref.entity, function(a, b)
                return all_entities[a].z < all_entities[b].z
            end)
        end
    end
end

--SPAWNER @global
Spawner = callable{
    __call = function(_, sys_type, template)
        template = template or {}
        template.type = sys_type

        return callable{
            is_spawner=true,
            type=sys_type,
            template=copy(template),
            __call = function(self, args)
                local new_entity = copy(self.template)
                if args and type(args) == 'table' then 
                    table.update(new_entity, args)
                end
                return World.add(new_entity)
            end,
            bind = function(self, new_template)
                return Spawner(self.type, new_template)
            end
        }
    end
}

stray_entities = {} -- {}
entity_sys_count = {} -- { uuid:# } (how many systems an entity belongs to)
entity_state = {} -- { uuid:state_name/nil } (what state the entity started in)
last_world_state = NO_STATE
world_state = NO_STATE
type_list = {} -- { type:{ entities... } }

type_add = function(obj)
    if obj.type ~= nil then 
        if not type_list[obj.type] then type_list[obj.type] = {} end 
        table.insert(type_list[obj.type], obj.uuid)
    end
end

type_remove = function(obj)
    if obj.type ~= nil and type_list[obj.type] ~= nil then 
        iterate(type_list[obj.type], function(_uuid)
            if _uuid == obj.uuid then return true end
        end)
    end
end

--WORLD @global
World = {
    add = function(obj)
        if obj.is_spawner then 
            return obj()
        end

        if not obj.z then obj.z = 0 end
        if not obj.uuid then obj.uuid = uuid() end 
        -- obj already in the world?
        if entity_state[obj.uuid] == nil then 
            entity_state[obj.uuid] = world_state
            entity_sys_count[obj.uuid] = 0  
    
            all_entities[obj.uuid] = obj
            table.insert(stray_entities, obj.uuid)
    
            type_add(obj)
        end         

        -- spawn any children?
        local children
        for k,v in pairs(obj) do 
            if type(v) == "table" and v.type then 
                local new_child = World.add(v)
                obj[k] = new_child
                
                if not children then children = {} end
                table.insert(children, {
                    uuid=new_child.uuid,
                    key=k
                })
            end
        end
        obj._children = children
        
        return obj
    end,
    remove = function(obj)
        System.remove(obj)
        entity_state[obj.uuid] = nil
        all_entities[obj.uuid] = nil
    end,
    get_type = function(_type)
        return type_list[_type] or {}
    end,
    update = function(dt)
        -- see if any system can use a stray entity
        iterate_entities(stray_entities, function(obj)
            if check_obj_state(obj) then
                return System.add(obj)
            end
        end)
        stray_entities = {}
        
        -- changing state
        if world_state ~= last_world_state then
            state_callback('enter')
            last_world_state = world_state
        else
            state_callback('update',dt)
        end
        World.process('update',{dt}) -- calls every system with an update
    end,
    set_state = function(name)
        state_callback('exit') 
        world_state = name or NO_STATE
    end,
    -- iterate all systems and their entities
    process = function(cb_name, args, wrapper_fn)
        for _, sys_id in ipairs(system_ids) do
            process_system(sys_id, cb_name, args or {}, wrapper_fn)
        end
    end,
    -- iterate one system's entities
    processOne = function(sys_id, cb_name, args, wrapper_fn)
        process_system(sys_id, cb_name, args or {}, wrapper_fn)
    end,
    draw = function()   
        local draw_world = function()
            World.process('draw', nil, World.draw_modifier)            
            state_callback('draw',dt)
        end
    
        local draw_camera = function()
            Draw{
                {'push'},
                {'color',Game.options.background_color},
                {'rect','fill',0,0,Game.width,Game.height},
                {'pop'}
            }
            -- if Camera.count() > 0 then
            --     Camera.useAll(draw_world)
            -- else 
                draw_world()
            -- end
        end
    
        local draw_game = function()
            Game.options.draw(function()
                -- if Game.effect then
                --     Game.effect:draw(draw_camera)
                -- else 
                    draw_camera()
                -- end
            end)
        end
     
        Draw.origin()
        local game_canvas = Game.canvas
        game_canvas:drawTo(draw_game)
        if Game.options.scale == true then
            game_canvas.pos.x, game_canvas.pos.y = Blanke.padx, Blanke.pady
            game_canvas.scale = Blanke.scale
        end

        -- World.draw_modifier(Game.canvas, function() game_canvas:draw() end)
        Effect.apply(Game, function()
            game_canvas:draw()
        end)

        if do_profiling then
            Draw.push()
            Draw.color('black')
            love.graphics.print(love.report or "Please wait...")
            Draw.pop()
        end
    end,
    draw_modifier = function(obj, fn) fn() end
}

--STATE
states = {} -- { state_name={ name=fn } }
-- @global
State = callable{
    __call = function(_, name, fns) 
        if not states[name] then states[name] = {} end
        table.update(states[name], fns)
    end,
    start       = function(name) World.set_state(name) end,
    switch      = function(name) World.set_state(name) end,
    restart     = function() World.set_state(world_state) end,
    stop        = function() World.set_state(NO_STATE) end
}
