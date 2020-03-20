require 'blanke_util'

local iterate, sortEntities
-- sys vars
local systems, system_ids
-- component vars
local component_defaults
-- entity vars
local entity_defaults, entity_functions
-- world vars
local sys_callback
local state_callback, check_obj_state
local all_entities, entity_sys_count, entity_state, last_world_state, world_state
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
    table.sort(t, function(a, b) 
        if a == nil and b == nil then
            return false
            end
            if a == nil then
            return true
            end
            if b == nil then
            return false
            end
        a._last_z = a.z
        b._last_z = b.z
        return a.z < b.z
    end)
end

systems = {} -- { sys_id: { entity:{}, new_entity:{ uuid:t/f } component:{ name }, callback:{ name:fn}, prop:{ k:v } } }
system_ids = {} -- { sys_id1, sys_id2 }

System = callable {
    __call = function(_, args)
        local sys_id = uuid()
        systems[sys_id] = { entity={}, new_entity={}, component={}, callback={}, prop={ index=1 } }
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
    add = function(obj) 
        local found_a_system = false
        for _, sys in ipairs(systems) do 
            for _, component in ipairs(sys.component) do 
                if obj[component] ~= nil then 
                    -- entity has a component that this system can process
                    entity_sys_count[obj.uuid] = entity_sys_count[obj.uuid] + 1
                    table.insert(sys.entity, obj)
                    sys.new_entity[obj.uuid] = true
                    found_a_system = true
                end
            end
        end
        return found_a_system
    end
}

-- register defaults for a component
component_defaults = {} -- { name={ prop=value } }
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

sys_callback = function(sys_ref, name, ...)
    if sys_ref.callback[name] then 
        return sys_ref.callback[name](...)
    end
end

state_callback = function(name, ...)
    if states[world_state] and states[world_state][name] then 
        return states[world_state][name](...)
    end
end

check_obj_state = function(obj)
    return entity_state[obj.uuid] == world_state
end

all_entities = {} -- {}
entity_sys_count = {} -- { uuid:# } (how many systems an entity belongs to)
entity_state = {} -- { uuid:state_name } (what state the entity started in)
last_world_state = ''
world_state = ''

World = {
    add = function(obj)
        for k,v in pairs(props) do 
            Component.exists(entity_defaults[name], k)
        end
        obj.uuid = uuid()
        entity_state[obj.uuid] = world_state
        if entity_sys_count[obj.uuid] == 0 then 
            table.insert(all_entities, obj)
        end
        return obj
    end,
    update = function(dt)
        -- see if any system can use a stray entity
        iterate(all_entities, function(obj)
            if check_obj_state(obj) then
                return System.add(obj)
            else 
                sys_callback('remove', obj)
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
        World.process('update',dt) -- calls every system with an update
    end,
    process = function(cb_name, ...)
        local sys_ref
        local proc_args = {...}
        for _, sys_id in ipairs(system_ids) do
            sys_ref = systems[sys_id]
            if sys_ref.callback[cb_name] then 
                -- iterate entities
                iterate(sys_ref.entity, function(obj)
                    -- obj was recently added
                    if sys_ref.new_entity[obj.uuid] then
                        sys_callback('add', obj)
                        sys.new_entity[obj.uuid] = false
                    end

                    local rem = sys_callback(cb_name, obj, unpack(proc_args))
                    if rem then 
                        -- remove the obj from the system
                        sys_callback('remove', obj)                        
                        entity_sys_count[obj.uuid] = entity_sys_count[obj.uuid] - 1
                        if entity_sys_count[obj.uuid] == 0 then 
                            -- entity is no longer part of any system
                            table.insert(all_entities, obj)
                        end
                    end
                    return rem
                end)
            end
        end
    end,
    set_state = function(name)
        state_callback('exit')
        world_state = name
        state_callback('enter')
    end
}

--STATE
states = {} -- { state_name={ name=fn } }
State = callable{
    __call = function(name, fns) 
        if not states[name] then states[name] = {} end
        for fn_name, fn in pairs(fns) do 
            states[name][fn_name] = fn
        end
    end,
    start       = function(name) World.set_state(name) end,
    switch      = function(name) World.set_state(name) end,
    restart     = function() World.set_state(world_state) end,
    stop        = function() World.set_state() end
}

Signal.emit('__main')

love.load = function() 
    if do_profiling then
        love.profiler = require 'profile'
        love.profiler.start()
    end 
end
love.frame = 0
love.update = function(dt) 
    if do_profiling then
        love.frame = love.frame + 1
        if love.frame > 60 and not love.report then 
            love.profiler.stop()
            love.report = love.profiler.report(do_profiling)
            print(love.report)
        end
    end

    World.update(dt)
end
love.draw = function() 
    World.process('draw') -- calls every system with a draw
    Draw.push()
    Draw.color('black')
    if do_profiling then
        love.graphics.print(love.report or "Please wait...")
    end
    Draw.pop()
end
love.resize = function(w, h) Game.updateWinSize() end
love.keypressed = function(key, scancode, isrepeat) Blanke.keypressed(key, scancode, isrepeat) end
love.keyreleased = function(key, scancode) Blanke.keyreleased(key, scancode) end
love.mousepressed = function(x, y, button, istouch, presses) Blanke.mousepressed(x, y, button, istouch, presses) end
love.mousereleased = function(x, y, button, istouch, presses) Blanke.mousereleased(x, y, button, istouch, presses) end
--BEGIN:LOVE.RUN
love.run = function()
  if love.math then love.math.setRandomSeed(os.time()) end
  if love.load then love.load(arg) end
  if love.timer then love.timer.step() end

  local dt = 0
  local fixed_dt = 1/60
  local accumulator = 0

  while true do
    if love.event then
      love.event.pump()
      for name, a, b, c, d, e, f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a
          end
        end
        love.handlers[name](a, b, c, d, e, f)
      end
    end
    if love.timer then
      love.timer.step()
      dt = love.timer.getDelta()
    end

    accumulator = accumulator + dt
    while accumulator >= fixed_dt do
      if love.update then love.update(fixed_dt) end
      accumulator = accumulator - fixed_dt
    end
    if love.graphics and love.graphics.isActive() then
      love.graphics.clear(love.graphics.getBackgroundColor())
      love.graphics.origin()
      if love.draw then love.draw() end
      love.graphics.present()
    end

    if love.timer then love.timer.sleep(0.0001) end
  end
end