local _NAME = ...
require(_NAME..'.util')
require(_NAME..'.ecs')
require(_NAME..'.systems')

local dt = 0
local fixed_dt = 1/60
local accumulator = 0
--BLANKE @global
Blanke = {
    load = function()
        love.frame = 0
        if do_profiling then
            love.profiler = require 'profile'
            love.profiler.start()
        end 
        Game.options.load()
        World.update(0)
        -- print_r(Game.options)
        Window.setSize()
    end,
    update = function(dt)   
        mouse_x, mouse_y = love.mouse.getPosition()
        if Game.options.scale == true then
            local scalex, scaley = Game.win_width / Game.width, Game.win_height / Game.height
            local scale = math.min(scalex, scaley)
            Blanke.padx, Blanke.pady = 0, 0
            if scalex > scaley then
                Blanke.padx = floor((Game.win_width - (Game.width * scale)) / 2)
            else 
                Blanke.pady = floor((Game.win_height - (Game.height * scale)) / 2)
            end
            -- offset mouse coordinates
            mouse_x = floor((mouse_x - Blanke.padx) / scale)
            mouse_y = floor((mouse_y - Blanke.pady) / scale)
            Blanke.scale = {
                x = scale,
                y = scale,
            }
        end

        accumulator = accumulator + dt
        while accumulator >= fixed_dt do

            if do_profiling then
                love.frame = love.frame + 1
                if love.frame > 60 and not love.report then 
                    love.profiler.stop()
                    love.report = love.profiler.report(do_profiling)
                    print(love.report)
                end
            end
            World.update(dt)
            
            accumulator = accumulator - fixed_dt
        end

        Game.time = Game.time + dt
        if Game.options.update(dt) == true then return end

        -- Physics.update(dt)
        -- Timer.update(dt)
        Signal.emit('update',dt)
        local key = Input.pressed('_fs_toggle') 
        if key and key.count == 1 then
            Window.toggleFullscreen()
        end            
        Input.keyCheck()
    end,
    draw = function()
        World.draw()
    end,
    resize = function(w,h)
        Game.win_width, Game.win_height, flags = love.window.getMode()
        if w and h then Game.win_width, Game.win_height = w, h end
        if not Game.options.scale then
            Game.width, Game.height = Game.win_width, Game.win_height
            Game.options.canvas.size = {Game.width, Game.height}
        end
    end,
    keypressed = function(key, scancode, isrepeat)
        Input.press(key, {scancode=scancode, isrepeat=isrepeat})
    end,
    keyreleased = function(key, scancode)
        Input.release(key, {scancode=scancode})
    end,
    mousepressed = function(x, y, button, istouch, presses) 
        Input.press('mouse', {x=x, y=y, button=button, istouch=istouch, presses=presses})
        Input.press('mouse'..tostring(button), {x=x, y=y, button=button, istouch=istouch, presses=presses})
    end,
    mousereleased = function(x, y, button, istouch, presses) 
        Input.press('mouse', {x=x, y=y, button=button, istouch=istouch, presses=presses})
        Input.release('mouse'..tostring(button), {x=x, y=y, button=button, istouch=istouch, presses=presses})
    end
}

Signal.emit('__main')
love.load = function() Blanke.load() end
love.update = function(dt) Blanke.update(dt) end
love.draw = function() Blanke.draw() end
love.resize = function(w, h) Blanke.resize() end
love.keypressed = function(key, scancode, isrepeat) Blanke.keypressed(key, scancode, isrepeat) end
love.keyreleased = function(key, scancode) Blanke.keyreleased(key, scancode) end
love.mousepressed = function(x, y, button, istouch, presses) Blanke.mousepressed(x, y, button, istouch, presses) end
love.mousereleased = function(x, y, button, istouch, presses) Blanke.mousereleased(x, y, button, istouch, presses) end
