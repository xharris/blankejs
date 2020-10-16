io.stdout:setvbuf('no')


love.filesystem.setRequirePath( "?.lua;?/init.lua;lua/?.lua;lua/?/init.lua" )
require("ecs")
      
function love.conf(t)
    t.console = true
    
    t.identity = "blanke.boredom"
    t.window.title = "boredom"
    -- t.gammacorrect = nil

end
