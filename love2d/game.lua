local Entity, Game, new
do
  local _obj_0 = require("blanke")
  Entity, Game, new = _obj_0.Entity, _obj_0.Game, _obj_0.new
end
Entity("Player", {
  image = 'soldier.png',
  update = function(self, dt)
    return print(dt)
  end
})
return Game({
  res = 'data',
  load = function()
    return Game.spawn("Player")
  end
})
