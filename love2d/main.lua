io.stdout:setvbuf('no')
local BlankeLoad, BlankeUpdate, BlankeDraw
do
  local _obj_0 = require("blanke")
  BlankeLoad, BlankeUpdate, BlankeDraw = _obj_0.BlankeLoad, _obj_0.BlankeUpdate, _obj_0.BlankeDraw
end
require("game")
love.load = function()
  return BlankeLoad()
end
love.update = function(dt)
  return BlankeUpdate(dt)
end
love.draw = function()
  return BlankeDraw()
end
