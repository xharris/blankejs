io.stdout:setvbuf('no')

package.path = "lua/?.lua;lua/?/init.lua;" .. package.path
require("ecs")
Game.options.auto_require = false
      
function love.conf(t)
    t.console = true
    
    t.window.title = "test_zone"
    -- t.gammacorrect = nil

end
