local Entity, Game
do
  local _obj_0 = require("blanke")
  Entity, Game = _obj_0.Entity, _obj_0.Game
end
return Game({
  load = function()
    return print("hi")
  end
})
