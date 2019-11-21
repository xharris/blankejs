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
local uuid = require("uuid")
require("printr")
local Game
do
  local objects
  local _base_0 = { }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, args)
      table.update(self.__class.options, args, {
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
  self.options = {
    res = '',
    load = function() end
  }
  objects = { }
  self.updatables = { }
  self.drawables = { }
  self.load = function()
    if self.__class.options.load then
      return self.__class.options.load()
    end
  end
  self.addObject = function(name, _type, args, spawn_class)
    if objects[name] == nil then
      objects[name] = {
        type = _type,
        args = args,
        spawn_class = spawn_class
      }
    end
  end
  self.spawn = function(name)
    local obj_info = objects[name]
    if obj_info ~= nil and obj_info.spawn_class then
      local instance = obj_info.spawn_class(obj_info.args)
      return instance
    end
  end
  Game = _class_0
end
local GameObject
do
  local _base_0 = {
    addUpdatable = function(self)
      self.updatable = true
      return table.insert(Game.updatables, self)
    end,
    addDrawable = function(self)
      self.drawable = true
      table.insert(Game.drawables, self)
      return table.sort(Game.drawables, function(a, b)
        return a.z < b.z
      end)
    end,
    destroy = function(self)
      self.destroyed = true
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.uuid = uuid()
      self.x, self.y, self.z = 0, 0, 0
      if self._spawn then
        self:_spawn()
      end
      if self.spawn then
        return self:spawn()
      end
    end,
    __base = _base_0,
    __name = "GameObject"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  GameObject = _class_0
end
local _Image
do
  local _parent_0 = GameObject
  local _base_0 = {
    _draw = function(self)
      return love.graphics.draw(self.image, self.x, self.y)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, args)
      _parent_0.__init(self)
      self.image = love.graphics.newImage(Game.options.res .. '/' .. args.file)
      return self:addDrawable()
    end,
    __base = _base_0,
    __name = "_Image",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  _Image = _class_0
end
local _Entity
do
  local _parent_0 = GameObject
  local _base_0 = {
    _update = function(self, dt)
      if self.update then
        self:update(dt)
      end
      local _list_0 = self.imageList
      for _index_0 = 1, #_list_0 do
        local img = _list_0[_index_0]
        img.x, img.y = self.x, self.y
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, args)
      _parent_0.__init(self)
      table.update(self, args)
      self.imageList = { }
      if args.image then
        if type(args.image) == 'table' then
          do
            local _accum_0 = { }
            local _len_0 = 1
            local _list_0 = args.image
            for _index_0 = 1, #_list_0 do
              local img = _list_0[_index_0]
              _accum_0[_len_0] = _Image({
                file = img
              })
              _len_0 = _len_0 + 1
            end
            self.imageList = _accum_0
          end
        else
          self.imageList = {
            _Image({
              file = args.image
            })
          }
        end
      end
      self:addUpdatable()
      return self:addDrawable()
    end,
    __base = _base_0,
    __name = "_Entity",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  _Entity = _class_0
end
local Entity
Entity = function(name, args)
  return Game.addObject(name, "Entity", args, _Entity)
end
local BlankeLoad
BlankeLoad = function()
  return Game.load()
end
local BlankeUpdate
BlankeUpdate = function(dt)
  local len = #Game.updatables
  for o = 1, len do
    local obj = Game.updatables[o]
    if obj.destroyed then
      Game.updatables[o] = nil
    else
      if obj._update then
        obj:_update(dt)
      end
    end
  end
end
local BlankeDraw
BlankeDraw = function()
  local len = #Game.drawables
  for o = 1, len do
    local obj = Game.drawables[o]
    if obj.destroyed then
      Game.drawables[o] = nil
    else
      if obj._draw then
        obj:_draw()
      end
    end
  end
end
return {
  BlankeLoad = BlankeLoad,
  BlankeUpdate = BlankeUpdate,
  BlankeDraw = BlankeDraw,
  Game = Game,
  Entity = Entity
}
