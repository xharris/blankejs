io.stdout:setvbuf('no')
package.path = package.path .. ";/home/xhh/Documents/blankejs/love2d/?.lua;/home/xhh/Documents/blankejs/love2d/lua/?/init.lua;/home/xhh/Documents/blankejs/love2d/lua/?.lua;/home/xhh/Documents/blankejs/love2d/plugins/?/init.lua;/home/xhh/Documents/blankejs/love2d/plugins/?.lua"
require 'moonscript'
local blanke = require "blanke"
blanke.Blanke.config = {
    scale = true,
    game_size = 3,
    window_size = 3
}
blanke.Blanke.config.window_flags = {
    borderless = false,
    resizable = false
}
function love.conf(t)
    t.console = true
    t.window = false
end
