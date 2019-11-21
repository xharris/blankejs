local is_object, p
do
  local _obj_0 = require("moon")
  is_object, p = _obj_0.is_object, _obj_0.p
end
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
table.keys = function(t)
  local _accum_0 = { }
  local _len_0 = 1
  for k, v in pairs(t) do
    _accum_0[_len_0] = k
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local uuid = require("uuid")
require("printr")
local Game
do
  local _class_0
  local objects
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, args)
      table.update(self.__class.options, args, {
        'res',
        'filter',
        'load',
        'draw',
        'update'
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
    filter = 'linear',
    load = function() end,
    update = function(dt) end,
    draw = function() end
  }
  objects = { }
  self.updatables = { }
  self.drawables = { }
  self.width = 0
  self.height = 0
  self.graphics = {
    clear = function(...)
      return love.graphics.clear(...)
    end
  }
  self.load = function()
    self.width, self.height = love.graphics.getDimensions()
    if type(Game.filter) == 'table' then
      love.graphics.setDefaultFilter(unpack(Game.options.filter))
    else
      love.graphics.setDefaultFilter(Game.options.filter, Game.options.filter)
    end
    if self.options.load then
      return self.options.load()
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
  self.drawObject = function(gobj, ...)
    local _list_0 = {
      ...
    }
    for _index_0 = 1, #_list_0 do
      local lobj = _list_0[_index_0]
      love.graphics.draw(lobj, gobj.x, gobj.y, math.rad(gobj.angle), gobj.scalex, gobj.scaley, gobj.offx, gobj.offy, gobj.shearx, gobj.sheary)
    end
  end
  self.isSpawnable = function(name)
    return objects[name] ~= nil
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
  local _class_0
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
    remUpdatable = function(self)
      self.updatable = false
    end,
    remDrawable = function(self)
      self.drawable = false
    end,
    _draw = function(self)
      if self.draw then
        return self:draw()
      end
    end,
    _update = function(self, dt)
      if self.update then
        return self:update(dt)
      end
    end,
    destroy = function(self)
      self.destroyed = true
      local _list_0 = self.child_keys
      for _index_0 = 1, #_list_0 do
        local k = _list_0[_index_0]
        self[k]:destroy()
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, args)
      self.uuid = uuid()
      self.x, self.y, self.z, self.angle, self.scalex, self.scaley = 0, 0, 0, 0, 1, nil
      self.offx, self.offy, self.shearx, self.sheary = 0, 0, 0, 0
      self.child_keys = { }
      if args then
        for k, v in pairs(args) do
          if type(v) == "string" and Game.isSpawnable(v) then
            self[k] = Game.spawn(v)
          else
            if is_object(v) then
              table.insert(self.child_keys, k)
              self[k] = v()
              args[k] = nil
            end
          end
        end
      end
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
local Canvas
do
  local _class_0
  local _parent_0 = GameObject
  local _base_0 = {
    _draw = function(self)
      return Game.drawObject(self, self.canvas)
    end,
    drawTo = function(self, obj)
      local last_canvas = love.graphics.getCanvas()
      love.graphics.setCanvas(self.canvas)
      if self.auto_clear then
        Game.graphics.clear()
      end
      if type(obj) == "function" then
        obj()
      else
        if is_object(obj) and obj._draw then
          obj:_draw()
        end
      end
      return love.graphics.setCanvas(last_canvas)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, args)
      _class_0.__parent.__init(self)
      self.angle = 0
      self.auto_clear = true
      self.canvas = love.graphics.newCanvas(Game.width, Game.height)
      return self:addDrawable()
    end,
    __base = _base_0,
    __name = "Canvas",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  Canvas = _class_0
end
local Image
do
  local _class_0
  local _parent_0 = GameObject
  local _base_0 = {
    _draw = function(self)
      return Game.drawObject(self, self.image)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, args)
      _class_0.__parent.__init(self)
      self.image = love.graphics.newImage(Game.options.res .. '/' .. args.file)
      if self._spawn then
        self:_spawn()
      end
      if self.spawn then
        self:spawn()(cs.newImage(Game.options.res .. '/' .. args.file))
      end
      if args.drawable ~= false then
        return self:addDrawable()
      end
    end,
    __base = _base_0,
    __name = "Image",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  Image = _class_0
end
local _Entity
do
  local _class_0
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
    end,
    _draw = function(self)
      local _list_0 = self.imageList
      for _index_0 = 1, #_list_0 do
        local img = _list_0[_index_0]
        img:_draw()
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, args)
      _class_0.__parent.__init(self, args)
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
              _accum_0[_len_0] = Image({
                file = img,
                drawable = false
              })
              _len_0 = _len_0 + 1
            end
            self.imageList = _accum_0
          end
        else
          self.imageList = {
            Image({
              file = args.image,
              drawable = false
            })
          }
        end
      end
      self:addUpdatable()
      self:addDrawable()
      if self.spawn then
        return self:spawn()
      end
    end,
    __base = _base_0,
    __name = "_Entity",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if Game.options.update(dt) == true then
    return 
  end
  local len = #Game.updatables
  for o = 1, len do
    local obj = Game.updatables[o]
    if obj.destroyed or not obj.updatable then
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
  if Game.options.draw() == true then
    return 
  end
  local len = #Game.drawables
  for o = 1, len do
    local obj = Game.drawables[o]
    if obj.destroyed or not obj.drawable then
      Game.drawables[o] = nil
    end
    if obj.draw ~= false then
      if obj.draw then
        obj:draw()
      else
        if obj._draw then
          obj:_draw()
        end
      end
    end
  end
end
return {
  BlankeLoad = BlankeLoad,
  BlankeUpdate = BlankeUpdate,
  BlankeDraw = BlankeDraw,
  Game = Game,
  Canvas = Canvas,
  Image = Image,
  Entity = Entity
}
