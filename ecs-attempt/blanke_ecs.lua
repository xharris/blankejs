local iterate, sortEntities
-- sys vars
local systems, system_ids
local system_effect
-- component vars
local component_defaults
-- entity vars
local entity_defaults, entity_functions
-- world vars
local sys_callback
local state_callback, check_obj_state
local all_entities, entity_sys_count, entity_state, last_world_state, world_state
local process_system
-- state vars
local states

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

systems = {} -- { sys_id: { entity:{ uuid }, entity:{ uuid:t/nil/'new' } component:{ name }, callback:{ name:fn}, prop:{ k:v } } }
system_ids = {} -- { sys_id1, sys_id2 }
system_entity = {} -- { sys_id: { ent_uuid:t/f } }

-- @global
System = callable {
    __call = function(_, args)
        local sys_id = uuid()
        systems[sys_id] = { entity={}, entity={}, component={}, callback={}, prop={ index=1 } }
        table.insert(system_ids, sys_id)

        local sys_ref = systems[sys_id]

        if args then 
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
        end
        
        table.sort(system_ids, function(a, b) 
            return systems[a].prop.index < systems[b].prop.index
        end)
    end,
    -- see if the object fits into any systems
    add = function(obj) 
        local sys_ref
        local found_a_system = false
        for _, sys_id in ipairs(system_ids) do 
            sys_ref = systems[sys_id]
            for _, component in ipairs(sys_ref.component) do 
                if obj[component] ~= nil then 
                    -- entity has a component that this system can process
                    entity_sys_count[obj.uuid] = entity_sys_count[obj.uuid] + 1
                    table.insert(sys_ref.entity, obj)
                    sys_ref.entity[obj.uuid] = 'new'
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
    end
}

-- register defaults for a component
component_defaults = {} -- { name={ prop=value } }
-- @global
Component = callable{
    __call = function(_, name, props)
        if type(name) == "table" then 
            for name, props in pairs(name) do 
                component_defaults[name] = props
            end
        else 
            component_defaults[name] = props
        end
    end,
    exists = function(name)
        return component_defaults[name] ~= nil
    end,
    use = function(entity, name)
        if component_defaults[name] then 
            entity[name] = copy(component_defaults[name])
        end
    end
}

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
    return entity_state[obj.uuid] ~= nil and (obj.persistent == true or entity_state[obj.uuid] == world_state)
end

process_system = function(sys_id, cb_name, args, wrapper_fn)
    local sys_ref = systems[sys_id]
    if sys_ref.callback[cb_name] then
        -- iterate entities
        iterate(sys_ref.entity, function(obj)
            -- obj was recently added
            if sys_ref.entity[obj.uuid] == 'new' then
                sys_callback(sys_ref, 'add', obj)
                obj_callback('spawn', obj)
                sys_ref.entity[obj.uuid] = true
            end

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

all_entities = {} -- {}
entity_sys_count = {} -- { uuid:# } (how many systems an entity belongs to)
entity_state = {} -- { uuid:state_name/nil } (what state the entity started in)
last_world_state = ''
world_state = ''

-- @global
World = {
    add = function(obj)
        if not obj.uuid then obj.uuid = uuid() end 
        if entity_state[obj.uuid] ~= nil then return obj end -- obj already in the world
        
        entity_state[obj.uuid] = world_state
        entity_sys_count[obj.uuid] = 0  

        table.insert(all_entities, obj)
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
    end,
    set_state = function(name)
        state_callback('exit') 
        world_state = name
    end,
    process = function(cb_name, args, wrapper_fn)
        for _, sys_id in ipairs(system_ids) do
            process_system(sys_id, cb_name, args or {}, wrapper_fn)
        end
    end,
    processOne = function(sys_id, cb_name, args, wrapper_fn)
        process_system(sys_id, cb_name, args or {}, wrapper_fn)
    end,
    draw = function()    
        Draw.origin()
        local actual_draw = function()
            World.process('predraw')
            
            World.process('draw', nil, Effect.process)
            
            World.process('postdraw')
            state_callback('draw',dt)
            if Game.options.postdraw then Game.options.postdraw() end
            Physics.drawDebug()
            Hitbox.draw()
        end
    
        local _drawGame = function()
            Draw{
                {'push'},
                {'color',Game.options.background_color},
                {'rect','fill',0,0,Game.width,Game.height},
                {'pop'}
            }
            if Camera.count() > 0 then
                Camera.useAll(actual_draw)
            else 
                actual_draw()
            end
        end
    
        local _draw = function()
            Game.options.draw(function()
                if Game.effect then
                    Game.effect:draw(_drawGame)
                else 
                    _drawGame()
                end
            end)
        end
    
        Blanke.game_canvas:drawTo(_draw)
        if Game.options.scale == true then
            Blanke.game_canvas.x, Blanke.game_canvas.y = Blanke.padx, Blanke.pady
            Blanke.game_canvas.scale = Blanke.scale
            Blanke.game_canvas:draw()
        
        else 
            Draw{
                {'push'},
                {'color','black'},
                {'rect','fill',0,0,Game.win_width,Game.win_height},
                {'pop'}
            }
            Blanke.game_canvas:draw()
        end
    
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
    stop        = function() World.set_state() end
}

--EFFECT (special drawing system)
system_effect = System{
    'effect',
    wrapper = function(obj, fn)
        

    end
}
Effect = callable{
    process = function(obj, fn)
        local used = false
        -- for _, name in ipairs(self.names) do 
        --     if not self.disabled[name] then 
        --         used = true
        --     end
        --     if not self.disabled[name] and library[name] and library[name].opt.draw then 
        --         library[name].opt.draw(self.shader_info.vars[name])
        --     end
        -- end
        
        if used then 
            local last_shader = love.graphics.getShader()
            local last_blend = love.graphics.getBlendMode()
            
            local front = self.front:getCanvas()
            front.blendmode = self.blendmode
            front.auto_clear = {1,1,1,0}

            front:drawTo(function()
                love.graphics.setShader()
                fn()
            end)
            
            love.graphics.setShader(self.shader_info.shader)
            front:draw()
            love.graphics.setShader(last_shader)
            
            love.graphics.setBlendMode(last_blend)
            self.front:release()
        else 
            fn()
        end
    end
}