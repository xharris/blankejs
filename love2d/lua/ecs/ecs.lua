local new_entities = {}
local dead_entities = {}

local entities = {}
local systems = {}
local system_ref = {}

local entity_templates = {}
local entity_callable = {}
local spawn

local entity_order = {}

local sys_callbacks = {'added','update','removed','draw'}

Entity = callable {
  __call = function(_, classname, props)
    if props then
      props.classname = props.classname or classname
      props['is_'..classname] = true

      -- extract system callbacks
      local new_ent_sys
      if Game.options.auto_system then 
        local sys_cbs = {}
        local need_sys = false
        for _, cb in ipairs(sys_callbacks) do 
          if type(props[cb]) == 'function' then 
            need_sys = true 
            sys_cbs[cb] = props[cb]
            props[cb] = nil
          end 
        end 
        if need_sys then 
          new_ent_sys = System(All('is_'..classname), sys_cbs)
          if sys_cbs.draw and not props.renderer then 
            props.renderer = new_ent_sys
          end 
        end 
      end

      -- adding entity template
      entity_templates[classname] = props
      entity_callable[classname] = callable {
        classname = classname,
        __call = function(_, ...)
          local args = {...}
          local t = copy(props)
          if type(args[1]) == 'table' then 
            table.update(t, args[1])
          end
          return World.add(t, args)
        end,
        new = function(args)
          return {
            _new = classname,
            args = args
          }
        end 
      }
      return entity_callable[classname], new_ent_sys

    elseif type(classname) == "table" then 
      return World.add(props)
    end 
  end,
  exists = function(classname)
    return entity_templates[classname] ~= null
  end,
  spawn = function(classname, props)
    if entity_templates[classname] then 
      -- spawn from entity template
      local t = copy(entity_templates[classname])
      
      if props then 
        table.update(t, props)
      end 
      return World.add(t)
    end 
  end
}

System = callable {
  __call = function(_, query, opt)
    local cb = copy(opt)
    local id = uuid()
    cb.order = nil 

    local sys_info = {
      uuid=id,
      query=query,
      order=opt.order,
      cb=cb,
      entities={},
      changed={},
      removed={},
      has_entity={}
    }
    table.insert(systems, sys_info)
    system_ref[id] = sys_info

    System.sort()
    return id
  end,
  order = {pre=-10000,_=0,post=10000},
  sort = function()
    table.sort(systems, function(a, b)
      if (type(a.order) ~= "number") then 
        a.order = a.order ~= nil and (System.order[a.order] or a.order) or System.order._
      end
      if (type(b.order) ~= "number") then 
        b.order = b.order ~= nil and (System.order[b.order] or b.order) or System.order._
      end
      return a.order < b.order
    end)
  end
}

All = function(...) return { type="all", args={...} } end
Some = function(...) return { type="some", args={...} } end
Not = function(...) return { type="not", args={...} } end
One = function(...) return { type="one", args={...} } end

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
    elseif qtype == "one" then 
      local found = 0
      for q = 1, #query.args do 
        if Test(query.args[q], obj, _not) then 
          found = found + 1
        end 
        if found > 1 then return false end 
      end
      if found == 1 then return true end  
    end 
  end 
end 

function Check(ent, args)
  local sys
  for i = 1, table.len(systems) do 
    sys = systems[i]
    if not sys.has_entity[ent.uuid] and Test(sys.query, ent) then
      sys.has_entity[ent.uuid] = true
      -- entity fits in this system
      table.insert(sys.entities, ent.uuid)
      if sys.cb.added then sys.cb.added(ent, args) end 
    end 
  end 
end 

function Add(ent, k, v) 
  if k then 
    ent[k] = (v == nil and true or v)
  end
  Check(ent)
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
    -- if sys.cb.removed then sys.cb.removed(ent) end 
  end 
end 

local z_sort = false
local check_z = function(ent)
  if ent.parent and ent.parent.z then ent.z = ent.parent.z end
  if not ent.z then ent.z = 0 end
  if ent._last_z ~= ent.z then 
    ent._last_z = ent.z
    z_sort = true
  end 
end 

System(All("size", "scale", "scalex", "scaley"), {
  added = function(ent)
    ent.scaled_size = {
      ent.size[1] * ent.scale * ent.scalex,
      ent.size[2] * ent.scale * ent.scaley
    }
  end,
  update = function(ent, dt)
    ent.scaled_size[1] = ent.size[1] * ent.scale * ent.scalex
    ent.scaled_size[2] = ent.size[2] * ent.scale * ent.scaley
  end
})

function getAlign(ent)
  local ax, ay = 0, 0
  local sizew, sizeh = ent.scaled_size[1], ent.scaled_size[2]
  local type_align = type(ent.align)

  if type_align == 'table' then 
    ax, ay = unpack(ent.align)

  elseif type_align == 'string' then 
    local align = ent.align
    
    if string.contains(align, 'center') then
        ax = 0.5
        ay = 0.5
    end
    if string.contains(align,'left') then
        ax = 0
    end
    if string.contains(align, 'right') then
        ax = 1
    end
    if string.contains(align, 'top') then
        ay = 0
    end
    if string.contains(align, 'bottom') then
        ay = 1
    end
    ent.align = {ax, ay} 
  end 
  return floor(ax * sizew), floor(ay * sizeh), sizew, sizeh
end

local transform = {}
function Render(_ent, skip_tf)    
  transform = {0,0,0,1,1,0,0,0,0}
  local drawable = _ent.drawable 
  local ent = _ent.parent or _ent
  local ax, ay, sizew, sizeh = getAlign(ent)
  local unscaled_ax, unscaled_ay = ax / ent.scale / ent.scalex, ay / ent.scale / ent.scaley 

  if not drawable then return end
  if type(drawable) == 'function' then
    drawable(_ent)

  else  
    local lg = love.graphics

    lg.push('all')
    lg.setColor(unpack(ent.color))
    lg.setBlendMode(unpack(ent.blendmode))
    
    local draw = function() 
      if not skip_tf then 
        transform = {
          ent.pos[1], ent.pos[2] ,
          ent.angle, ent.scale * ent.scalex, ent.scale * ent.scaley,
          unscaled_ax, unscaled_ay,
          ent.shear[1], ent.shear[2]
        }
      end 
      if ent.quad then 
        lg.draw(drawable, ent.quad, unpack(transform))
      else
        lg.draw(drawable, unpack(transform))
      end
    end

    if ent.effect and ent.effect.classname == "Blanke.Effect" then 
      ent.effect:draw(draw)
    else 
      draw()
    end 

    if Game.debug or ent.debug then 
      if not skip_tf then
        lg.translate(transform[1], transform[2])
        lg.rotate(transform[3])
        lg.shear(transform[8], transform[9])
      end 
      Draw.color(_ent.debug_color or 'red')
      Draw.rect('line',
        -ax, 
        -ay, 
        ent.scaled_size[1],
        ent.scaled_size[2]
      )
      Draw.circle('fill', 0, 0, 3)
      lg.shear(-transform[8], -transform[9])
      if _ent.parent then 
        Draw.print(ent.classname..'->'.._ent.classname)
      else 
        Draw.print(ent.classname)
      end 
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
  align = { 0, 0 },
  z = 0
}

local check_sub_entities
check_sub_entities = function(ent, checked)
  if not checked then checked = {} end
  if checked and checked[ent] then return end 
  for k,v in pairs(ent) do 
    if type(v) == 'table' then 
      if v._new and entity_callable[v._new] then 
        -- found a sub-entity
        if v.args.child == true then 
          v.args.parent = ent
        end 
        ent[k] = entity_callable[v._new](v.args)
      else 
        checked[v] = true
        check_sub_entities(v, checked)
      end 
    end 
  end
end

World = {
  add = function(ent, args) 
    -- add new entity
    if not ent.uuid then 
      ent.uuid = uuid()
      entities[ent.uuid] = ent 
    end 

    table.defaults(ent, draw_defaults)
    table.insert(entity_order, ent.uuid)
    check_z(ent)
    check_sub_entities(ent)
    Check(ent, args)

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
    local sys, draw, ent, parent
    for e = 1, #entity_order do
      ent = entities[entity_order[e]]
      parent = ent.parent or ent
      if parent.draw ~= false then
        sys = system_ref[parent.renderer] 
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