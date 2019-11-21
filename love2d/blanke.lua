table.update = function(old_t, new_t, keys)
  if keys == nil then
    for k, v in pairs(new_t) do
      old_t[k] = v
    end
  else
    for _index_0 = 1, #keys do
      local k = keys[_index_0]
      if new_t[k] ~= nil then
        old_t[k] = new_t[k]
      end
    end
  end
end
local Game
do
  local options, objects
  local _base_0 = { }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, args)
      table.update(options, args, {
        'res',
        'load'
      })
      return nil
    end,
    __base = _base_0,
    __name = "Game"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  options = {
    res = '',
    load = function() end
  }
  objects = { }
  self.updatables = { }
  self.drawables = { }
  self.load = function()
    if options.load then
      return options.load()
    end
  end
  self.addObject = function(name, _type, args, opt)
    if objects[name] == nil then
      objects[name] = {
        type = _type,
        args = args
      }
    end
    return table.update(objects[name], opt)
  end
  self.spawn = function(name)
    local obj_info = objects[name]
    if obj_info ~= nil and obj_info.spawn_class then
      local instance = obj_info.spawn_class(obj_info.args)
      if obj_info.updatable then
        table.insert(self.__class.updatables, instance)
      end
      if obj_info.drawables then
        table.insert(self.__class.drawables, instance)
      end
      return instance
    end
  end
  Game = _class_0
end
local _Entity
do
  local _base_0 = { }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, args)
      return table.update(self, args)
    end,
    __base = _base_0,
    __name = "_Entity"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  _Entity = _class_0
end
local Entity
Entity = function(name, args)
  return Game.addObject(name, "Entity", args, {
    spawn_class = _Entity,
    updatable = true,
    drawable = true
  })
end
local BlankeLoad
BlankeLoad = function()
  return Game.load()
end
local BlankeUpdate
BlankeUpdate = function(dt)
  local _list_0 = Game.updatables
  for _index_0 = 1, #_list_0 do
    local obj = _list_0[_index_0]
    if obj.update then
      obj:update(dt)
    end
  end
end
local BlankeDraw
BlankeDraw = function() end
return {
  BlankeLoad = BlankeLoad,
  BlankeUpdate = BlankeUpdate,
  BlankeDraw = BlankeDraw,
  Game = Game,
  Entity = Entity
}
