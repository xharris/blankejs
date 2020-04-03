io.stdout:setvbuf('no')
package.path = package.path .. ";D:/Documents/PROJECTS/blankejs/love2d/?.lua;D:/Documents/PROJECTS/blankejs/love2d/?/init.lua;D:/Documents/PROJECTS/blankejs/love2d/lua/?/init.lua;D:/Documents/PROJECTS/blankejs/love2d/lua/?.lua;D:/Documents/PROJECTS/blankejs/love2d/plugins/?/init.lua;D:/Documents/PROJECTS/blankejs/love2d/plugins/?.lua"
require "blanke"
function love.conf(t)
    t.console = true
    t.gammacorrect = nil
    --t.window = nil
end
