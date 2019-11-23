io.stdout:setvbuf('no')
local Blanke
do
  local _obj_0 = require("blanke")
  Blanke = _obj_0.Blanke
end
require("game")
love.load = function()
  return Blanke.load()
end
love.update = function(dt)
  return Blanke.update(dt)
end
love.draw = function()
  return Blanke.draw()
end
love.keypressed = function(key, scancode, isrepeat)
  return Blanke.keypressed(key, scancode, isrepeat)
end
love.keyreleased = function(key, scancode)
  return Blanke.keyreleased(key, scancode)
end
love.mousepressed = function(x, y, button, istouch, presses)
  return Blanke.mousepressed(x, y, buttons, istouch, presses)
end
love.mousereleased = function(x, y, button, istouch, presses)
  return Blanke.mousereleased(x, y, button, istouch, presses)
end
