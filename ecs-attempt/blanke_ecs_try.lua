require 'blanke_util'
require 'blanke_ecs'
require 'blanke_systems'

Signal.emit('__main')

love.load = function() 
    if do_profiling then
        love.profiler = require 'profile'
        love.profiler.start()
    end 
    
    Game.options.load()
end
love.frame = 0
love.update = function(dt) 
    if do_profiling then
        love.frame = love.frame + 1
        if love.frame > 60 and not love.report then 
            love.profiler.stop()
            love.report = love.profiler.report(do_profiling)
            print(love.report)
        end
    end

    World.update(dt)
end
love.draw = function() 
    World.draw()

    
    Draw.origin()
    local actual_draw = function()
        Blanke.iterDraw(Game.drawables)
        State.draw()
        if Game.options.postdraw then Game.options.postdraw() end
        Physics.drawDebug()
        Hitbox.draw()
    end

    local _drawGame = function()
        Draw{
            {'push'},
            {'color',Game.options.background_color},
            {'rect','fill',0,0,Game.width,Game.height},
            {'pop'}
        }
        if Camera.count() > 0 then
            Camera.useAll(actual_draw)
        else 
            actual_draw()
        end
    end

    local _draw = function()
        Game.options.draw(function()
            if Game.effect then
                Game.effect:draw(_drawGame)
            else 
                _drawGame()
            end
        end)
    end

    Blanke.game_canvas:drawTo(_draw)
    if Game.options.scale == true then
        Blanke.game_canvas.x, Blanke.game_canvas.y = Blanke.padx, Blanke.pady
        Blanke.game_canvas.scale = Blanke.scale
        Blanke.game_canvas:draw()
    
    else 
        Draw{
            {'push'},
            {'color','black'},
            {'rect','fill',0,0,Game.win_width,Game.win_height},
            {'pop'}
        }
        Blanke.game_canvas:draw()
    end
end

love.resize = function(w, h) Game.updateWinSize() end
love.keypressed = function(key, scancode, isrepeat) Blanke.keypressed(key, scancode, isrepeat) end
love.keyreleased = function(key, scancode) Blanke.keyreleased(key, scancode) end
love.mousepressed = function(x, y, button, istouch, presses) Blanke.mousepressed(x, y, button, istouch, presses) end
love.mousereleased = function(x, y, button, istouch, presses) Blanke.mousereleased(x, y, button, istouch, presses) end
--BEGIN:LOVE.RUN
love.run = function()
  if love.math then love.math.setRandomSeed(os.time()) end
  if love.load then love.load(arg) end
  if love.timer then love.timer.step() end

  local dt = 0
  local fixed_dt = 1/60
  local accumulator = 0

  while true do
    if love.event then
      love.event.pump()
      for name, a, b, c, d, e, f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a
          end
        end
        love.handlers[name](a, b, c, d, e, f)
      end
    end
    if love.timer then
      love.timer.step()
      dt = love.timer.getDelta()
    end

    accumulator = accumulator + dt
    while accumulator >= fixed_dt do
      if love.update then love.update(fixed_dt) end
      accumulator = accumulator - fixed_dt
    end
    if love.graphics and love.graphics.isActive() then
      love.graphics.clear(love.graphics.getBackgroundColor())
      love.graphics.origin()
      if love.draw then love.draw() end
      love.graphics.present()
    end

    if love.timer then love.timer.sleep(0.0001) end
  end
end