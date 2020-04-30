io.stdout:setvbuf('no')

package.path = "./lua/?/init.lua;./lua/?;" .. package.path
require("blanke")
      
function love.conf(t)
    t.console = true
    
    t.window.title = "dodgem"
    -- t.gammacorrect = nil

end
