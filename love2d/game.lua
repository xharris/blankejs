local Entity, Game
do
  local _obj_0 = require("blanke")
  Entity, Game = _obj_0.Entity, _obj_0.Game
end
Game({
  res = 'data',
  load = function()
    return Game.spawn("Player")
  end
})
return Entity("Player", {
  image = 'soldier.png',
  update = function(self, dt)
    self.x = self.x + (5 * dt)
  end
})
