io.stdout:setvbuf('no')
package.path = package.path .. ";/home/xhh/Documents/blankejs/love2d/?.lua;/home/xhh/Documents/blankejs/love2d/lua/?/init.lua;/home/xhh/Documents/blankejs/love2d/lua/?.lua"
require 'moonscript'
package.moonpath = package.moonpath .. ";/home/xhh/Documents/blankejs/love2d/?.moon"
function love.conf(t)
    t.console = true
end