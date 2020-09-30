local new_entities = {}
local dead_entities = {}

local entities = {}
local systems = {}

local entity_templates = {}
local spawn

local entity_order = {}

Entity = callable {
  __call = function(_, classname, props)
    if props then
      props.classname = props.classname or classname
      -- adding entity template
      entity_templates[classname] = props

      return callable {
        __call = function(_, ...)
          local args = {...}
          local t = copy(props)
          if type(args[1]) == 'table' then 
            table.update(t, args[1])
          end
          return World.add(t, unpack(args))
        end 
      }

    elseif type(classname) == "string" then 
      -- spawn from entity template
      local t = copy(entity_templates[classname])
      if t then 
        return World.add(t)
      end
      
    elseif type(classname) == "table" then 
      return World.add(props)
    end 
  end,
  spawn = function(classname, props)
    local t = copy(props)
    if props then 
      table.update(t, props)
    end 
    return World.add(t)
  end
}

System = callable {
  __call = function(_, query, opt)
    local cb = copy(opt)
    local id = uuid()
    cb.order = nil 

    table.insert(systems, {
      uuid=id,
      query=query,
      order=opt.order,
      cb=cb,
      entities={},
      changed={},
      removed={},
      has_entity={}
    })

    System.sort()
    return id
  end,
  order = {},
  sort = function()
    table.sort(systems, function(a, b)
      if (type(a.order) ~= "number") then 
        a.order = a.order ~= nil and (System.order[a.order] or a.order) or (System.order._ or 0)
      end
      if (type(b.order) ~= "number") then 
        b.order = b.order ~= nil and (System.order[b.order] or b.order) or (System.order._ or 0)
      end
      return a.order > b.order
    end)
  end
}

All = function(...) return { type="all", args={...} } end
Some = function(...) return { type="some", args={...} } end
Not = function(...) return { type="not", args={...} } end

Test = function(query, obj, _not) 
  if type(query) == "string" then
    if (_not and obj[query] == nil) or (not _not and obj[query] ~= nil)  then 
      return true 
    end
    return false
  end 
  if type(query) == "table" and query.args then 
    local qtype = query.type
    if qtype == "all" then 
      return table.every(query.args, function(q) return Test(q, obj, _not) end)
    elseif qtype == "some" then 
      return table.some(query.args, function(q) return Test(q, obj, _not) end)
    elseif qtype == "not" then 
      return table.every(query.args, function(q) return Test(q, obj, not _not) end)
    end 
  end 
end 

function Add(ent, k, v) 
  local sys
  if k then 
    ent[k] = (v == nil and true or v)
  end
  for i = 1, table.len(systems) do 
    sys = systems[i]
    if not sys.has_entity[ent.uuid] and Test(sys.query, ent) then
      sys.has_entity[ent.uuid] = true
      -- entity fits in this system
      table.insert(sys.entities, ent.uuid)
      if sys.cb.added then sys.cb.added(ent, v) end 
    end 
  end 
end 

local remove_prop = {}
function Remove(ent, k)
  for i = 1, table.len(systems) do 
    systems[i].changed[ent.uuid] = true 
  end 
  table.insert(remove_prop, {ent,k})
end 

function Destroy(ent) 
  local sys
  ent.destroyed = true
  for i = 1, table.len(systems) do 
    sys = systems[i]
    sys.removed[ent.uuid] = true 
    if sys.cb.removed then sys.cb.removed(ent) end 
  end 
end 

local z_sort = false
local check_z = function(ent)
  if not ent.z then ent.z = 0 end
  if ent._last_z ~= ent.z then 
    ent._last_z = ent.z
    z_sort = true
  end 
end 


function Render(_ent, skip_tf)
  local drawable = _ent.drawable 
  local ent = _ent.parent or _ent

  if drawable then 
    local lg = love.graphics

    lg.push('all')
    lg.setColor(unpack(ent.color))
    lg.setBlendMode(unpack(ent.blendmode))
    
    local draw = function()
      local ax, ay = unpack(ent.align)
      
      if skip_tf then 
        lg.draw(drawable)
      elseif ent.quad then 
        lg.draw(drawable, ent.quad, 
          ent.pos[1], ent.pos[2], ent.angle, 
          ent.scale * ent.scalex, 
          ent.scale * ent.scaley, 
          ax, ay, ent.shearx, ent.sheary
        )
      else
        lg.draw(drawable, 
          ent.pos[1], ent.pos[2], ent.angle, 
          ent.scale * ent.scalex, 
          ent.scale * ent.scaley, 
          ax, ay, ent.shearx, ent.sheary
        )
      end
    end

    if ent.effect and ent.effect.classname == "Blanke.Effect" then 
      ent.effect:draw(draw)
    else 
      draw()
    end 

    if ent.debug then 
      Draw.color('red')
      Draw.rect('line',ent.pos[1],ent.pos[2],ent.size[1],ent.size[2])
      Draw.print(ent.classname..' -> '.._ent.classname, ent.pos[1]+5, ent.pos[2]+5)
    end

    lg.pop()
  end 
end

local draw_defaults = {
  pos = { 0, 0 },
  size = { 0, 0 },
  angle = 0,
  scale = 1,
  scalex = 1,
  scaley = 1,
  shear = { 0, 0 },
  color = { 1, 1, 1, 1 },
  blendmode = { 'alpha' },
  align = { 0, 0 }
}

World = {
  add = function(ent, args) 
    -- add new entity
    if not ent.uuid then 
      ent.uuid = uuid()
      entities[ent.uuid] = ent 
    end 

    table.defaults(ent, draw_defaults)
    Add(ent)

    table.insert(entity_order, ent.uuid)
    check_z(ent)

    return ent 
  end,
  remove = function(obj) table.insert(dead_entities, obj) end,
  update = function(dt)
    local ent, sys
    
    -- remove dead entities 
    for n = 1, table.len(dead_entities) do 
      ent = dead_entities[n]
      for s = 1, table.len(systems) do 
        sys.removed[ent.uuid] = true
      end 
    end 
    if table.len(dead_entities) > 0 then 
      table.filter(entity_order, function(eid)
        return eid ~= ent.uuid
      end)
    end 
    dead_entities = {}
    -- update systems
    for s = 1, table.len(systems) do 
      sys = systems[s]
      local update, removed = sys.cb.update, sys.cb.removed 
      if update then 
        table.filter(sys.entities, function(eid)
          ent = entities[eid]
          -- entity was removed from world
          if sys.removed[eid] then 
            sys.removed[eid] = nil 
            return false 

          -- entity property was changed
          elseif sys.changed[eid] then 
            sys.changed[eid] = nil 
            if Test(sys.query, ent) then 
              -- entity can stay
              check_z(ent)
              return true 
            else 
              -- entity removed from system 
              if removed then removed(ent) end
              sys.has_entity[eid] = nil
              return false 
            end 
          else 
            update(ent, dt)
            check_z(ent)
          end 
          return true            
        end)
        -- check for changed entities that were not previously in this system 
        for eid,_ in pairs(sys.changed) do 
          if Test(sys.query, entities[eid]) and not table.includes(sys.entities, eid) then
            table.insert(sys.entities, eid)
          end 
        end 
        sys.changed = {}
      end 
    end 

    for r = 1, #remove_prop do
      remove_prop[1][remove_prop[2]] = nil
    end 
    remove_prop = {}

    if z_sort then 
      table.sort(entity_order, function(a, b)
        return entities[a].z < entities[b].z
      end)
      z_sort = false
    end 
  end,
  draw = function()
    local sys, draw
    for eid, ent in pairs(entities) do
      if ent.draw ~= false then
        sys = systems[ent.renderer] 
        if sys then 
          sys.cb.draw(ent)
        elseif ent.drawable then 
          -- default renderer
          Render(ent)
        end 
      end
    end
  end
}