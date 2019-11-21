local Entity, Game, Canvas
do
  local _obj_0 = require("blanke")
  Entity, Game, Canvas = _obj_0.Entity, _obj_0.Game, _obj_0.Canvas
end
local is_object, p
do
  local _obj_0 = require("moon")
  is_object, p = _obj_0.is_object, _obj_0.p
end
local bob, my_canv
Game({
  res = 'data',
  filter = 'nearest',
  load = function()
    bob = Game.spawn("Player")
  end
})
Entity("Player", {
  image = 'soldier.png',
  canv = Canvas,
  update = function(self, dt)
    self.x = self.x + (5 * dt)
    self.canv.scalex = self.canv.scalex + (2 * dt)
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
