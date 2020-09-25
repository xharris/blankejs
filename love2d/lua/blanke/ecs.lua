local new_entities = {}
local dead_entities = {}

local entities = {}
local systems = {}

local entity_templates = {}
local spawn

Entity = callable {
  __call = function(_, classname, props)
    if props then 
      -- adding entity template
      entity_templates[classname] = props

      return function(args)
        local t = copy(props)
        table.update(t, args)
        return World.add(t)
      end 

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
    cb.order = nil 

    table.insert(systems, {
      query=query,
      order=opt.order,
      cb=cb,
      entities={},
      changed={},
      removed={}
    })

    System.sort()
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
    return _not and obj[query] == nil or obj[query] ~= nil 
  end 
  if type(query) == "table" and query.args then 
    local qtype = query.type
    if qtype == "all" then 
      return table.every(query.args, function(q) return Test(q, obj, _not) end)
    elseif qtype == "some" then 
      return table.some(query.args, function(q) return Test(q, obj, _not) end)
    elseif qtype == "not" then 
      return table.some(query.args, function(q) return Test(q, obj, not _not) end)
    end 
  end 
end 

function Add(ent, k, v) 
  ent[k] = (v == nil and true or v)
  for i = 1, table.len(systems) do 
    systems[i].changed[ent.uuid] = true 
  end 
end 

function Remove(ent, k)
  for i = 1, table.len(systems) do 
    systems[i].changed[ent.uuid] = true 
  end 
  ent[k] = nil
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

World = {
  add = function(obj) table.insert(new_entities, obj) end,
  remove = function(obj) table.insert(dead_entities, obj) end,
  update = function(dt)
    local ent, sys 
    -- add new entities
    for n = 1, table.len(new_entities) do 
      ent = new_entities[n]
      if not ent.uuid then 
        ent.uuid = uuid()
        entities[ent.uuid] = ent 
      end 

      for s = 1, table.len(systems) do 
        sys = systems[s]
        if Test(sys.query, ent) then
          -- entity fits in this system
          table.insert(sys.entities, ent.uuid)
          if sys.cb.added then sys.cb.added(ent) end 
        end 
      end 
    end 
    -- update systems
    for s = 1, table.len(systems) do 
      sys = systems[s]
      local update, removed = sys.cb.update, sys.cb.removed 
      if update then 
        table.filter(sys.entities, function(eid)
          -- entity was removed from world
          if sys.removed[eid] then 
            sys.removed[eid] = nil 
            return false 

          -- entity property was changed
          elseif sys.changed[eid] then 
            sys.changed[eid] = nil 
            if Test(sys.query, entities[eid]) then 
              -- entity can stay
              return true 
            else 
              -- entity removed from system 
              if removed then removed(entities[eid]) end 
              return false 
            end 
          else 
            update(entities[eid], dt)
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
    new_entities = {}
  end
}