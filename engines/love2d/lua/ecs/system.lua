local entities = {} -- { uuid={ } }
local components = {} -- { uuid{ entity=uuid } }
local systems = {} -- { uuid={ } }
local rend_systems = {} -- { uuid={ } }
--system
local callback2system = {} -- { callback={ sys_id } }
local component2system = {} -- { comp_name={ sys_id } }
local type2system = {} -- { type={ sys_id } }
local addSystem, removeSystem
local component_requirements = {} -- { comp_name={ comp_names } }
--component
local comp_name2uuid = {} -- { comp_name={ comp_id } }
local component_defaults = {} -- { comp_name=props }
--entity
local entity_templates = {} -- { name={} }
local add_template
ENTITY_REQUIRES = {'pos','quad','angle','size','scale','offset','shear','blendmode'}
--rendersystem

--world
local require_component
local check_obj_requirements
local type2entity = {} -- { type={ uuid } }
local type_count = {} -- { type=# }
local type_count_incr
local type_count_decr
local destroyed_entities = {} -- { uuid }
local destroyed_components = {} -- { uuid }
local need_cleaning = false
local remove_from_world
local system_add_fresh_obj
--state
local states = {} -- { name={fns} }
local STATES = {
  NONE=1,
  RESTART=2,
  STOP=3
}

local iterate 

iterate = function(t, fn) -- fn(): return true to remove an object
  local len = #t
  local offset = 0
  if len == 0 then return end
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

--SYSTEM
System = function(opt)
  local sys_id = uuid()
  local comp_name = opt.component
  if comp_name then
    -- store name of component this system deals with
    if not component2system[comp_name] then 
      component2system[comp_name] = {}
    end
    table.insert(component2system[comp_name], sys_id)
    -- store other requirements
    if opt.requires and #opt.requires > 0 then 
      if not component_requirements[comp_name] then 
        component_requirements[comp_name] = {}
      end
      local comp_req = component_requirements[comp_name]
      for _, req in ipairs(opt.requires) do 
        if not comp_req[req] then 
          table.insert(comp_req, req)
          comp_req[req] = true
        end
      end
    end
  end
  -- store callbacks this system has
  for k, v in pairs(opt) do 
    if k ~= 'requires' and k ~= 'type' and k ~= 'component' then 
      if not callback2system[k] then 
        callback2system[k] = {}
      end
      table.insert(callback2system[k], sys_id)
    end
  end
  if opt.type and not type2entity[opt.type] then 
    if not type2system[opt.type] then type2system[opt.type] = {} end
    table.insert(type2system[opt.type], sys_id)
    type2entity[opt.type] = {}
  end

  systems[sys_id] = opt
end

--COMPONENT
Component = function(name, props)
  if type(name) == 'table' then
    local use_fns = {} 
    for name2, props2 in pairs(name) do 
      use_fns[name2] = Component(name2, props2)
    end
    return use_fns
  end
  -- add component name list
  if not comp_name2uuid[name] then 
    comp_name2uuid[name] = {} 
  end

  component_defaults[name] = props

  return function(new_props)
    return use(name, new_props)
  end
end

--@global: to be used before World.add, retrieves a loose component (one without uuid)
use = function(name, props, obj)
  if comp_name2uuid[name] and (not props or not props.is_component) then
    props = props or {}
    props.is_component = name
    local new_props = table.update(copy_shallow(component_defaults[name]), props)
    if obj and not obj[name] then 
      obj[name] = new_props
    end
    if obj then require_component(obj, name) end
    return new_props
  end
  return props
end

add_template = function(name, template)
  if not entity_templates[name] then 
    entity_templates[name] = copy(template)
  else
    table.update(entity_templates[name], template)
  end
end

--ENTITY (combo template/system setup that returns a spawner)
Entity = function(name, template)
  local has_methods = false
  local methods = {}
  local require_added = {} -- { comp_name=t/f }
  local requires = {} -- { comp_name }

  local entity_requires = ENTITY_REQUIRES
  for _, req in ipairs(entity_requires) do 
    require_added[req] = true
    table.insert(requires, req)
  end

  for k, v in pairs(template) do
    -- get those methods outta here!
    if type(v) == 'function' then 
      has_methods = true
      methods[k] = v
      template[k] = nil
    end 
    -- guess if there are illegitamate(?) components
    if type(v) == 'table' and World.guess_components then 
      template[k] = use(k, v)
      if template[k].is_component and not require_added[k] then 
        require_added[k] = true
        table.insert(requires, k)
      end
    end
  end
  add_template(name, template)
  -- create system for this entity if it has functions attached to it
  if has_methods then 
    methods.type = name
    methods.requires = requires
    System(methods)
  end
     
  return Spawner(name, template)
end

--SPAWNER
Spawner = function(_type, new_template)
  if new_template then 
    entity_templates[_type] = new_template
  end
  local template_keys = table.keys(new_template or {})

  return function(spawn_props)
    spawn_props = spawn_props or {}
    spawn_props.type = _type

    local template = entity_templates[_type]
    local new_entity = {} -- copy(template or {}) --{}
    local key
    for i=1,#template_keys do 
      key = template_keys[i]
      new_entity[key] = copy_shallow(template[key]) --template[key]
    end
    table.update(new_entity, spawn_props)

    World.add(new_entity)
    return new_entity
  end
end

system_add_fresh_obj = function(obj, sys_id)
  local sys_ref = systems[sys_id]
  if (obj.is_entity and sys_ref.type == obj.type) or (obj.is_component and sys_ref.component == obj.is_component) then
    if sys_ref.add then
      sys_ref.add(obj)
    end
  end
end

-- check if object has all of their systems requirements
check_obj_requirements = function(obj, sys_id)
  local sys_ref = systems[sys_id]
  if sys_ref.requires and #sys_ref.requires > 0 then 
    for _, req in ipairs(sys_ref.requires) do
      require_component(obj, req)
    end
  end
end

require_component = function(obj, comp_name)
  local obj_comp = obj[comp_name]
  -- could this be a component?  
  if component_defaults[comp_name] ~= nil and (obj_comp == nil or (type(obj_comp) == 'table' and obj_comp.is_component and not obj_comp.uuid)) then 
    obj_comp = use(comp_name, obj_comp) 
    -- add entity uuid reference to components
    obj_comp.entity_uuid = obj.uuid
    obj_comp.state_name = obj.state_name
    obj_comp.uuid = uuid() 
    components[obj_comp.uuid] = obj_comp
    table.insert(comp_name2uuid[comp_name], obj_comp.uuid)

    obj[comp_name] = obj_comp
  end
  if type(obj_comp) == "table" and obj_comp.is_component then
    if component_requirements[obj_comp.is_component] then
      -- find what other components are necessary
      for _, req in ipairs(component_requirements[obj_comp.is_component]) do 
        require_component(obj, req)
      end
    end
    if component2system[obj_comp.is_component] then
      for _, sys_id in ipairs(component2system[obj_comp.is_component]) do 
        -- check_obj_requirements(obj, sys_id, true)
        system_add_fresh_obj(obj_comp, sys_id)
      end
    end
  end
end

remove_from_world = function(obj)
  if not need_cleaning then need_cleaning = {} end 

  if obj.is_entity then 
    table.insert(destroyed_entities, obj.uuid)
    World.remove(obj)
    need_cleaning.entity = true
    type_count_decr(obj.type)

  elseif obj.is_component then 
    table.insert(destroyed_components, obj.uuid)
    need_cleaning.component = true

  end

  return true
end

RenderSystem = function(opt)
  local sys = {
    uuid = uuid(),
    render = opt.render or function(obj, draw) draw() end
  }
  rend_systems[sys.uuid] = sys
  return function() return sys.uuid end
end

type_count_incr = function(_type)
  if not type_count[_type] then type_count[_type] = 0 end
  type_count[_type] = type_count[_type] + 1
end
type_count_decr = function(_type)
  if not type_count[_type] then type_count[_type] = 0 end
  type_count[_type] = type_count[_type] - 1
end

--WORLD
World = {
  guess_components = true,
  -- for adding entities with components
  add = function(obj)
    if obj.is_component then return obj end
    obj.is_entity = true
    if not obj.uuid then 
      obj.uuid = uuid()
      entities[obj.uuid] = obj
      obj.state_name = State.current
    end
    for k,v in pairs(obj) do
      require_component(obj, k)
    end
    if obj.type then 
      -- obj has entity type
      if not type2entity[obj.type] then 
        type2entity[obj.type] = {}
      end
      table.insert(type2entity[obj.type], obj.uuid)
      local sys_ref
      for _, sys_id in ipairs(type2system[obj.type]) do
        -- get system requirements
        check_obj_requirements(obj, sys_id)
        sys_ref = systems[sys_id]
        system_add_fresh_obj(obj, sys_id)
      end
      type_count_incr(obj.type)
    end
    return obj
  end,
  remove = function(obj) 
    -- remove this obj 
    obj.destroyed = true
    -- remove components
    for k,v in pairs(obj) do 
      if type(v) == 'table' and v.is_component then 
        v.destroyed = true
      end
    end
  end,
  remove_all = function(obj, fn)
    
  end,
  process = function(callback, ...)
    local args = {...}
    --  iterate callback2system
    --    if system.type ~= nil
    --      iterate type2entity
    --        if entity.destroyed: remove
    --        else: call syscallback(entities[component.entity])
    --    iterate component2system
    --      if component.destroyed: remove
    --      else: call syscallback(entities[component.entity])
    if callback2system[callback] then 
      local sys_ref, obj_ref, comp_ref
      local sys_ref_component
      -- iter systems with this callback
      iterate(callback2system[callback], function(sys_id)
        sys_ref = systems[sys_id]
        if sys_ref.type ~= nil then 
          -- iter objects of this system's type
          iterate(type2entity[sys_ref.type], function(obj_id)
            obj_ref = entities[obj_id]
            if State.check_obj(obj_ref) then 
              return remove_from_world(obj_ref) 
            end
            if obj_ref.destroyed then
              return remove_from_world(obj_ref)
            end
            if sys_ref[callback](obj_ref, unpack(args)) then
              return remove_from_world(obj_ref)
            end
          end)
        end
        -- iter components in system
        sys_ref_component = sys_ref.component
        if sys_ref_component and comp_name2uuid[sys_ref_component] then 
          iterate(comp_name2uuid[sys_ref_component], function(comp_id)
            comp_ref = components[comp_id]
            if State.check_obj(comp_ref) then 
              return remove_from_world(comp_ref) 
            end

            obj_ref = entities[comp_ref.entity_uuid]
            if obj_ref.destroyed or comp_ref.destroyed then
              return remove_from_world(comp_ref)
            end
            if sys_ref[callback](comp_ref, unpack(args)) then
              return remove_from_world(comp_ref)
            end
          end)
        end
      end)
    end
  end,
  clean = function()
    if need_cleaning then 
      -- clean entities
      if need_cleaning.entity then 
        iterate(destroyed_entities, function(obj)
          
        end)
        destroyed_entities = {}
      end
      -- clean components
      if need_cleaning.component then
        iterate(destroyed_entities, function(obj)
          
        end)
        destroyed_components = {}
      end
      need_cleaning = nil
    end
  end,
  stats = function(v)
    if v == 'type' then 
      local list = {}
      for _type, count in pairs(type_count) do 
        table.insert(list, _type..'='..count)
      end
      return table.join(list, ', ')
    end
  end,
  get_type_count = function(t)
    return type_count[t]
  end,
  update = function(dt)
    if dt == 0 then
      --print_r(component_defaults)
      --print("SYSTEMS")
      --print_r(systems)
      --print("ENTITIES")
      --print_r(entities) 
      --print("COMPONENTS")
      --print_r(components)
    end
    World.process('update', dt)
    World.clean()
    State.callback('update', dt)
    State.check()
  end,
  draw = function()
    World.process('draw')
    State.callback('draw')
  end,
  render = function(obj, prop_obj)
    local object = obj.object 
    if object and object.is_stack then 
        object = object.value
    end
    if object then 
        local main_obj = prop_obj or obj 
        -- local blendmode = extract(main_obj, 'blendmode')
        if not main_obj.has_draw_components then 
            main_obj.has_draw_components = true
            EcsUtil.extract_draw_components(main_obj)
        end
        Draw.setBlendMode(unpack(main_obj.blendmode))
        
        local renderer = rend_systems[main_obj.renderer]
        if renderer then 
          renderer.render(main_obj, function()
            love.graphics.draw(object, EcsUtil.get_draw_components(main_obj))
          end)
        else
          love.graphics.draw(object, EcsUtil.get_draw_components(main_obj))
        end
    end
  end
}

-- get a component from an entity or return some defaults
-- defaults do not override component_defaults unless override=True
-- @global
extract = function(obj, comp_name, defaults, override)
  assert(component_defaults[comp_name] or defaults ~= nil, "No such component '"..comp_name.."'")
  
  -- make sure object has component
  if obj[comp_name] == nil then 
      require_component(obj, comp_name)
  end 
  
  if override then 
    obj[comp_name] = defaults or copy_shallow(component_defaults[comp_name])
  end
  return obj[comp_name]
end

get_entity = function(component)
  if component.entity_uuid then 
    return entities[component.entity_uuid] or {}
  end 
  return {}
end

--STATE@global
State = callable{
    __call = function(_, name, fns) 
      if type(name) == "string" then
        if not states[name] then states[name] = {} end
        table.update(states[name], fns)
      end
    end,
    current     = STATES.NONE,
    next        = STATES.NONE,
    start       = function(name)
      State.switch(name)
    end,
    switch      = function(name) 
      if name == State.current then 
        State.restart()
      else
        State.next = name
      end
    end,
    restart     = function() 
      State.next = STATES.RESTART
    end,
    stop        = function() 
      State.next = STATES.STOP 
    end,
    callback    = function(callback, ...)
      local state = states[State.current]
      if state and state[callback] then 
        state[callback](...)
      end
    end,
    check     = function(callback, ...)
      -- restart
      if State.next == STATES.RESTART then
        State.callback('leave')
        State.next = State.current
        State.current = STATES.NONE

      -- stop
      elseif State.next == STATES.STOP then 
        State.current = STATES.NONE
        State.next = STATES.NONE
        State.callback('leave')

      -- switch
      elseif State.next ~= STATES.NONE then 
        if State.current ~= STATES.NONE then 
          State.callback('leave')
        end
        State.current = State.next
        State.next = STATES.NONE
        State.callback('enter')
      end
    end,
    check_obj = function(obj)
      if not obj.persistent and obj.state_name ~= State.current then 
        return true
      end
    end
}
