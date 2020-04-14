local _NAME = ...
require(_NAME..'.util')
require(_NAME..'.ecs')
require(_NAME..'.systems')

local do_profiling = nil -- false/#

local dt = 0
local fixed_dt = 1/60
local accumulator = 0
--BLANKE @global
Blanke = {
    load = function()
        love.frame = 0
        if do_profiling then
            love.profiler = require 'profile'
        end 
        Game.options.load()
        Game.love_version = {love.getVersion()}
        World.draw_modifier = function(obj, fn)
            Effect.apply(obj, fn)
        end
        World.add(Game)
        if Game.options.initial_state then 
            State.start(Game.options.initial_state)
        end
        World.update(0)
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

        local update = function(_dt)
            if do_profiling then
                love.profiler.start()
            end
            World.update(_dt)
            if do_profiling then
                love.frame = love.frame + 1
                if love.frame > 60 and not love.report then 
                    love.profiler.stop()
                    love.report = love.profiler.report(do_profiling)
                    print(love.report)
                end
            end
            Timer.update(_dt)

            Game.time = Game.time + _dt
            if Game.options.update(_dt) == true then return end
        end

        if Game.options.fps then 
            fixed_dt = 1/Game.options.fps
        else 
            fixed_dt = nil
        end
        if fixed_dt ~= nil then
            accumulator = accumulator + dt
            while accumulator >= fixed_dt do
                update(fixed_dt)
                accumulator = accumulator - fixed_dt
            end
        else 
            update(dt)
        end

        -- Physics.update(dt)
        -- Timer.update(dt)
        Signal.emit('update',dt)
        local key = Input.pressed('_fs_toggle') 
        if key and key.count == 1 then
            Window.toggleFullscreen()
        end            
        Input.keyCheck()
        reset_tracks()
    end,
    draw = function()
        local draw_camera = function()
            Draw{
                {'push'},
                {'color',Game.options.background_color},
                {'rect','fill',0,0,Game.width,Game.height},
                {'pop'}
            }
            -- if Camera.count() > 0 then
            --     Camera.useAll(draw_world)
            -- else 
                World.draw()
            -- end
        end
    
        local draw_game = function()
            Game.options.draw(function()
                -- if Game.effect then
                --     Game.effect:draw(draw_camera)
                -- else 
                    draw_camera()
                -- end
            end)
        end
     
        Draw.origin()
        local game_canvas = Game.canvas
        --
        --print_r(game_canvas)
        game_canvas:drawTo(draw_game)
        if Game.options.scale == true then
            game_canvas.pos.x, game_canvas.pos.y = Blanke.padx, Blanke.pady
            game_canvas.scale = Blanke.scale
        end
        game_canvas:draw()
        
    end,
    resize = function(w,h)
        Game.win_width, Game.win_height, flags = love.window.getMode()
        if w and h then Game.win_width, Game.win_height = w, h end
        if not Game.options.scale then
            Game.width, Game.height = Game.win_width, Game.win_height
            Game.canvas.size = {Game.width, Game.height}
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
