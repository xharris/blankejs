io.stdout:setvbuf('no')

package.path = "lua/?.lua;lua/?/init.lua;" .. package.path
require("blanke")
      
function love.conf(t)
    t.console = true
    
    t.window.title = "dodgem"
    -- t.gammacorrect = nil

end
