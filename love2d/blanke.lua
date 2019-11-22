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
table.every = function(t)
  for k, v in pairs(t) do
    if not v then
      return false
    end
  end
  return true
end
table.some = function(t)
  for k, v in pairs(t) do
    if v then
      return true
    end
  end
  return false
end
table.len = function(t)
  local c = 0
  for k, v in pairs(t) do
    c = c + 1
  end
  return c
end
table.hasValue = function(t, val)
  for k, v in pairs(t) do
    if v == val then
      return true
    end
  end
  return false
end
table.slice = function(t, start, finish)
  local i, res
  i, res, finish = 1, { }, finish or table.len(t)
  for j = start, finish do
    res[i] = t[j]
    i = i + 1
  end
  return res
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
  self.spawn = function(name, args)
    local obj_info = objects[name]
    if obj_info ~= nil and obj_info.spawn_class then
      local instance = obj_info.spawn_class(obj_info.args, args)
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
          local arg_type = type(v)
          local new_obj = nil
          if arg_type == "string" and Game.isSpawnable(v) then
            new_obj = Game.spawn(v)
          else
            if is_object(v) then
              table.insert(self.child_keys, k)
              new_obj = v()
            else
              if arg_type == "table" then
                if type(v[1]) == "string" then
                  new_obj = Game.spawn(v[1], table.slice(v, 2))
                else
                  if is_object(v[1]) then
                    table.insert(self.child_keys, k)
                    new_obj = v[1](unpack(table.slice(v, 2)))
                  end
                end
              end
            end
          end
          if new_obj then
            self[k] = new_obj
            args[k] = nil
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
    __init = function(self, w, h, settings)
      if w == nil then
        w = Game.width
      end
      if h == nil then
        h = Game.height
      end
      if settings == nil then
        settings = { }
      end
      _class_0.__parent.__init(self)
      self.angle = 0
      self.auto_clear = true
      self.width = w
      self.height = h
      self.canvas = love.graphics.newCanvas(self.width, self.height, settings)
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
    __init = function(self, args, spawn_args)
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
        if spawn_args then
          return self:spawn(unpack(spawn_args))
        else
          return self:spawn()
        end
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
local Input
do
  local _class_0
  local name_to_input, input_to_name, options, pressed, released
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, inputs, _options)
      for name, inputs in pairs(inputs) do
        Input.addInput(name, inputs, _options)
      end
      table.update(options, _options)
      return nil
    end,
    __base = _base_0,
    __name = "Input"
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
  name_to_input = { }
  input_to_name = { }
  options = {
    norepeat = { },
    combo = { }
  }
  pressed = { }
  released = { }
  self.addInput = function(name, inputs, options)
    do
      local _tbl_0 = { }
      for _index_0 = 1, #inputs do
        local i = inputs[_index_0]
        _tbl_0[i] = false
      end
      name_to_input[name] = _tbl_0
    end
    for _index_0 = 1, #inputs do
      local i = inputs[_index_0]
      if not input_to_name[i] then
        input_to_name[i] = { }
      end
      if not table.hasValue(input_to_name[i], name) then
        table.insert(input_to_name[i], name)
      end
    end
  end
  self.pressed = function(name)
    return pressed[name]
  end
  self.released = function(name)
    return released[name]
  end
  self.press = function(key, extra)
    if input_to_name[key] then
      local _list_0 = input_to_name[key]
      for _index_0 = 1, #_list_0 do
        local name = _list_0[_index_0]
        name_to_input[name][key] = true
        local combo = table.hasValue(options.combo, name)
        if (combo and table.every(name_to_input[name])) or (not combo and table.some(name_to_input[name])) then
          pressed[name] = extra
        end
      end
    end
  end
  self.release = function(key, extra)
    if input_to_name[key] then
      local _list_0 = input_to_name[key]
      for _index_0 = 1, #_list_0 do
        local name = _list_0[_index_0]
        name_to_input[name][key] = false
        local combo = table.hasValue(options.combo, name)
        if pressed[name] and (combo or not table.some(name_to_input[name])) then
          pressed[name] = false
          released[name] = extra
        end
      end
    end
  end
  self.releaseCheck = function()
    released = { }
  end
  Input = _class_0
end
local Draw
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, instructions)
      for _index_0 = 1, #instructions do
        local instr = instructions[_index_0]
        local name, args = instr[1], table.slice(instr, 2)
        Draw[name](unpack(args))
      end
    end,
    __base = _base_0,
    __name = "Draw"
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
  self.color = function(...)
    if #{
      ...
    } == 0 then
      return love.graphics.setColor(1, 1, 1, 1)
    else
      return love.graphics.setColor(...)
    end
  end
  Draw = _class_0
end
local draw_functions = {
  'arc',
  'circle',
  'clear',
  'discard',
  'ellipse',
  'line',
  'points',
  'polygon',
  'rectangle'
}
local draw_aliases = {
  polygon = 'poly',
  rectangle = 'rect'
}
for _index_0 = 1, #draw_functions do
  local fn = draw_functions[_index_0]
  Draw[draw_aliases[fn] or fn] = function(...)
    return love.graphics[fn](...)
  end
end
local Blanke = {
  load = function()
    return Game.load()
  end,
  update = function(dt)
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
    return Input.releaseCheck()
  end,
  draw = function()
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
          obj:draw(function()
            if obj._draw then
              return obj:_draw()
            end
          end)
        else
          if obj._draw then
            obj:_draw()
          end
        end
      end
    end
  end,
  keypressed = function(key, scancode, isrepeat)
    return Input.press(key, {
      scancode = scancode,
      isrepeat = isrepeat
    })
  end,
  keyreleased = function(key, scancode)
    return Input.release(key, {
      scancode = scancode
    })
  end,
  mousepressed = function(x, y, button, istouch, presses)
    return Input.press('mouse', {
      x = x,
      y = y,
      button = button,
      istouch = istouch,
      presses = presses
    })
  end,
  mousereleased = function(x, y, button, istouch, presses)
    return Input.release('mouse', {
      x = x,
      y = y,
      button = button,
      istouch = istouch,
      presses = presses
    })
  end
}
return {
  Blanke = Blanke,
  Game = Game,
  Canvas = Canvas,
  Image = Image,
  Entity = Entity,
  Input = Input,
  Draw = Draw
}
