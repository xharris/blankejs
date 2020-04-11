-- @global
NO_STATE = '_'

local iterate, sortEntities
-- sys vars
local systems, system_ids
local system_effect
local sys_add
-- component vars
local component_defaults
local component_type
-- entity vars
local entity_defaults, entity_functions
-- world vars
local sys_callback
local state_callback, check_obj_state
local all_entities, entity_sys_count, entity_state, last_world_state, world_state
local process_system
local world_add
-- state vars
local states
-- track vars
local entity_track, tracks_changed
local reset_tracks

iterate = function(t, fn) -- fn(): return true to remove an object
    local len = #t
    local offset = 0
    local resort = false
    for o, obj in ipairs(t) do
        local obj = t[o]
        if obj then 
            if obj.destroyed then 
                offset = offset + 1
            else
                if fn(obj, o) == true then
                    offset = offset + 1 
                else 
                    t[o] = nil
                    t[o - offset] = obj
                    -- sort later?
                    if obj.z then 
                        if obj.z then obj.z = floor(obj.z) end
                    end
                    if not obj._last_z or obj._last_z ~= obj.z then
                        resort = true
                    end
                end
            end
        end
    end
    if resort then 
        sortEntities(t)
    end
end

sortEntities = function(t)
    sort(t, 'z')
end

systems = {} -- { sys_id: { entity:{ uuid }, entity:{ uuid:t/nil/'new' }, component:{ name }, callback:{ name:fn}, prop:{ k:v } } }
system_ids = {} -- { sys_id1, sys_id2 }
system_entity = {} -- { sys_id: { ent_uuid:t/f } }
system_type = {} -- { sys_id: type_str }

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

sys_add = function(sys_ref, obj)
    if not sys_ref.entity[obj.uuid] then 
        entity_sys_count[obj.uuid] = entity_sys_count[obj.uuid] + 1
        sys_ref.entity[obj.uuid] = 'new'
        table.insert(sys_ref.entity, obj)
    end
    -- obj was recently added
    if sys_ref.entity[obj.uuid] == 'new' then
        sys_callback(sys_ref, 'add', obj)
        obj_callback('spawn', obj)
        sys_ref.entity[obj.uuid] = true
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

        systems[sys_id] = { entity={}, entity={}, type=(args.type or nil), component={}, callback={}, prop={ index=1 } }
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
            if obj.type and obj.type == system_type[sys_id] then 
                -- this system handles entities of this type
                sys_add(sys_ref, obj)
            end
            for _, component in ipairs(sys_ref.component) do 
                if obj[component] ~= nil then 
                    -- this system handles entities with this component
                    sys_add(sys_ref, obj)
                    found_a_system = true
                end
            end
        end
        return found_a_system
    end,
    remove = function(obj, sys_ref)
        if not sys_ref then
            -- remove object from all systems
            for _, sys_id in ipairs(system_ids) do 
                System.remove(obj, systems[sys_id])
            end
        else
            -- remove object from one system
            if sys_ref.entity[obj.uuid] then 
                obj_callback(sys_ref, 'destroy', obj)
                sys_callback(sys_ref, 'remove', obj)                        
                entity_sys_count[obj.uuid] = entity_sys_count[obj.uuid] - 1
                if entity_sys_count[obj.uuid] == 0 then 
                    -- entity is no longer part of any system
                    table.insert(all_entities, obj)
                end
            end
        end
    end,
    -- is the object in at least one system
    contains = function(obj)
        for _, sys_id in ipairs(system_ids) do
            if systems[sys_id].entity[obj.uuid] then 
                return true
            end
        end 
    end,
    stats = function()
        local stats = {} 
        for _, sys_id in ipairs(system_ids) do 
            local sys_ref = systems[sys_id]
            table.insert(stats, (system_type[sys_id] or table.join(sys_ref.component, '-')) .. '=' .. #sys_ref.entity)
        end
        return table.join(stats, ', ') 
    end
}

-- register defaults for a component
component_defaults = {} -- { name={ prop=value } }
component_type = {} -- { name=type(prop) }
-- @global
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
            if comp_type == "table" then 
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
                entity[name] = copy(component_defaults[name])
            else 
                entity[name] = component_defaults[name]
            end
        else 
            entity[name] = {}
        end
    end
}

-- get a component from an entity or return some defaults
-- defaults do not override component_defaults unless override=True
-- @global
extract = function(obj, comp_name, defaults, override)
    assert(Component.exists(comp_name) or defaults ~= nil, "No such component '"..comp_name.."'")
    
    -- make sure object has component
    if obj[comp_name] == nil then 
        Component.use(obj, comp_name)
    end 
    local default = component_defaults[comp_name]
    if defaults ~= nil then 
        default = defaults 
    end
    -- iterate keys 
    if type(default) == 'table' then 
        if override then 
            table.update(obj[comp_name], default)
        else
            table.defaults(obj[comp_name], default)
        end
    elseif obj[comp_name] == nil then
        obj[comp_name] = default
    end
    return obj[comp_name]
end

entity_track = {} -- { table_ref={ var=last_val } }
tracks_changed = {} -- { table_ref={ var=new_value } }

-- call track(obj, 'myvar') after it's been set
--@global
track = function(obj, comp_name) 
    if not entity_track[obj] then entity_track[obj] = {} end 
    entity_track[obj][comp_name] = obj[comp_name]
end

-- changed(obj, 'myvar') will return true/false if myvar has changed since the last track()/changed()
--@global
changed = function(obj, comp_name)
    local last_vars = entity_track[obj]
    if last_vars then 
        if last_vars[comp_name] ~= obj[comp_name] then 
            if not tracks_changed[obj] then 
                table.insert(tracks_changed, obj)
                tracks_changed[obj] = {}
            end 
            tracks_changed[obj][comp_name] = obj[comp_name]
            return true
        end
    end
    return false
end

reset_tracks = function()
    table.update_more(entity_track, tracks_changed)
    tracks_changed = {}
end

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

-- @global
obj_callback = function(obj, name, ...)
    if obj[name] then obj[name](...) end
end

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
        iterate(sys_ref.entity, function(obj)
            local rem 
            if wrapper_fn then 
                wrapper_fn(obj, function() 
                    rem = sys_callback(sys_ref, cb_name, obj, unpack(args))
                end)
            else
                rem = sys_callback(sys_ref, cb_name, obj, unpack(args))
            end
            if rem then 
                -- remove the obj from the system
                System.remove(obj, sys_ref)
            end
            return rem
        end)
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
            template=template,
            __call = function(self, args)
                local new_entity = copy(self.template)
                if args and type(args) == 'table' then 
                    table.update(new_entity, args)
                end
                return World.add(new_entity)
            end
        }
    end
}

all_entities = {} -- {}
entity_sys_count = {} -- { uuid:# } (how many systems an entity belongs to)
entity_state = {} -- { uuid:state_name/nil } (what state the entity started in)
last_world_state = NO_STATE
world_state = NO_STATE

--WORLD @global
World = {
    add = function(obj)
        if obj.is_spawner then 
            return obj()
        end

        if not obj.z then obj.z = 0 end
        if not obj.uuid then obj.uuid = uuid() end 
        if entity_state[obj.uuid] ~= nil then return obj end -- obj already in the world
        
        entity_state[obj.uuid] = world_state
        entity_sys_count[obj.uuid] = 0  

        table.insert(all_entities, obj)

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
    end,
    update = function(dt)
        -- see if any system can use a stray entity
        iterate(all_entities, function(obj)
            if check_obj_state(obj) then
                return System.add(obj)
            else 
                return true
            end
        end)
        -- changing state
        if world_state ~= last_world_state then
            state_callback('enter')
            last_world_state = world_state
        else
            state_callback('update',dt)
        end
        World.process('update',{dt}) -- calls every system with an update
        reset_tracks()
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
        Draw.origin()
        local draw_world = function()
            World.process('predraw')
            
            World.process('draw') -- , nil, Effect.process)
            
            World.process('postdraw')
            state_callback('draw',dt)
            if Game.options.postdraw then Game.options.postdraw() end
            -- Physics.drawDebug()
            -- Hitbox.draw()
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
    
        local game_canvas = Game.options.canvas
        game_canvas:drawTo(draw_game)
        if Game.options.scale == true then
            game_canvas.pos.x, game_canvas.pos.y = Game.padx, Game.pady
            game_canvas.scale = Blanke.scale
        end
        game_canvas:draw()
    
        if do_profiling then
            Draw.push()
            Draw.color('black')
            love.graphics.print(love.report or "Please wait...")
            Draw.pop()
        end
    end
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

--CACHE
-- @global
Cache = {}
do 
    local storage = {}
    Cache.group = function(name) return Cache[name] end
    Cache.key = function(group_name, key) return (Cache[group_name] and Cache[group_name][key]) end
    Cache.get = function(group_name, key, fn_not_found)
        if not storage[group_name] then storage[group_name] = {} end 
        if storage[group_name][key] then 
            return storage[group_name][key] 
        elseif fn_not_found then
            storage[group_name][key] = fn_not_found(key)
            return storage[group_name][key]
        end
    end
    Cache.stats = function()
        local str = '' 
        for name, list in pairs(storage) do 
            str = str .. name .. '=' .. table.len(list) .. ' '
        end
        print(str)
    end
end

--STACK
-- @global
Stack = class{
    init = function(self, fn_new)
        self.stack = {} -- { { used:t/f, value:?, is_stack:true, release:fn() } }
        self.fn_new = fn_new
    end,
    new = function(self, obj, remake)
        local found = false
        for _, s in ipairs(self.stack) do 
            if not s.used then 
                s.used = true 
                if remake then 
                    s.value = self.fn_new(obj)
                end
                return s
            end
        end
        if not found then 
            local new_uuid = uuid()
            local new_stack_obj = {
                uuid=new_uuid,
                used=true,
                value=self.fn_new(obj),
                is_stack=true,
                release=function()
                    self:release(new_uuid)
                end
            }
            table.insert(self.stack, new_stack_obj)
            return new_stack_obj
        end
    end,
    release = function(self, object)
        for _, s in ipairs(self.stack) do 
            if s.uuid == object.uuid then 
                s.used = false
                return 
            end
        end
    end
}