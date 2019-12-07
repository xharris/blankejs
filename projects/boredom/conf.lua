io.stdout:setvbuf('no')
package.path = package.path .. ";D:/Documents/PROJECTS/blankejs/love2d/?.lua;D:/Documents/PROJECTS/blankejs/love2d/lua/?/init.lua;D:/Documents/PROJECTS/blankejs/love2d/lua/?.lua;D:/Documents/PROJECTS/blankejs/love2d/plugins/?/init.lua;D:/Documents/PROJECTS/blankejs/love2d/plugins/?.lua"
require 'moonscript'
local blanke = require "blanke"
blanke.Blanke.config.scale = false
blanke.Blanke.config.width = 800
blanke.Blanke.config.height = 600
function love.conf(t)
    t.console = true
    t.window.width = 400
    t.window.height = 300
    t.window.borderless = false
    t.window.resizable = true
end
