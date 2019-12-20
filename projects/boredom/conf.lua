io.stdout:setvbuf('no')
package.path = package.path .. ";/home/xhh/Documents/blankejs/love2d/?.lua;/home/xhh/Documents/blankejs/love2d/?/init.lua;/home/xhh/Documents/blankejs/love2d/lua/?/init.lua;/home/xhh/Documents/blankejs/love2d/lua/?.lua;/home/xhh/Documents/blankejs/love2d/plugins/?/init.lua;/home/xhh/Documents/blankejs/love2d/plugins/?.lua"
require "blanke"
function love.conf(t)
    t.console = true
    --t.window = false
end
