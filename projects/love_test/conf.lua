io.stdout:setvbuf('no')
package.path = package.path .. ";/home/xhh/Documents/blankejs/love2d/?.lua;/home/xhh/Documents/blankejs/love2d/lua/?/init.lua;/home/xhh/Documents/blankejs/love2d/lua/?.lua;/home/xhh/Documents/blankejs/love2d/plugins/?/init.lua;/home/xhh/Documents/blankejs/love2d/plugins/?.lua"
require 'moonscript'
blanke = require "blanke"
blanke.Blanke.config.scale = false
function love.conf(t)
    t.console = true
    t.window.width = 300
    t.window.height = 300
    t.window.borderless = false
    t.window.resizable = false
end
