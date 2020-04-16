io.stdout:setvbuf('no')
package.path = package.path .. ";love2d/?.lua;love2d/?/init.lua;love2d/lua/?/init.lua;love2d/lua/?.lua;love2d/plugins/?/init.lua;love2d/plugins/?.lua"
require "blanke"
function love.conf(t)
    t.console = true
    
    t.window.title = "boredom"
    -- t.gammacorrect = nil

end
