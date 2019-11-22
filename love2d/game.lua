local Entity, Game, Canvas, Input
do
  local _obj_0 = require("blanke")
  Entity, Game, Canvas, Input = _obj_0.Entity, _obj_0.Game, _obj_0.Canvas, _obj_0.Input
end
local is_object, p
do
  local _obj_0 = require("moon")
  is_object, p = _obj_0.is_object, _obj_0.p
end
Game({
  res = 'data',
  filter = 'nearest',
  load = function()
    local bob = Game.spawn("Player")
  end
})
Input({
  left = {
    "left",
    "a"
  },
  right = {
    "right",
    "d"
  },
  up = {
    "up",
    "w"
  }
}, {
  no_repeat = {
    "up"
  }
})
Entity("Player", {
  image = 'soldier.png',
  canv = Canvas,
  update = function(self, dt)
    local hspeed = 20
    if Input.pressed('right') then
      self.x = self.x + (hspeed * dt)
    end
    if Input.pressed('left') then
      self.x = self.x - (hspeed * dt)
    end
    if Input.released('up') then
      self.y = self.y - (100 * dt)
    end
    return self.canv:drawTo(self)
  end,
  draw = false
})
return Entity("FakePlayer", {
  image = 'soldier.png',
  spawn = function(self)
    self.x = Game.width / 2
  end
})
