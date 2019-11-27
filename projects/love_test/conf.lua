io.stdout:setvbuf('no')
package.path = package.path .. ";D:/Documents/PROJECTS/blankejs/love2d/?.lua"
require 'moonscript'
package.moonpath = package.moonpath .. ";D:/Documents/PROJECTS/blankejs/love2d/?.moon"
function love.conf(t)
    t.console = true
end
