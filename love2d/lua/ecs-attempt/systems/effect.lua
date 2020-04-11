
--EFFECT (special drawing system)
system_effect = System{
  'effect',
  wrapper = function(obj, fn)
      

  end
}
Effect = callable{
  process = function(obj, fn)
      local used = false
      -- for _, name in ipairs(self.names) do 
      --     if not self.disabled[name] then 
      --         used = true
      --     end
      --     if not self.disabled[name] and library[name] and library[name].opt.draw then 
      --         library[name].opt.draw(self.shader_info.vars[name])
      --     end
      -- end
      
      if used then 
          local last_shader = love.graphics.getShader()
          local last_blend = love.graphics.getBlendMode()
          
          local front = self.front:getCanvas()
          front.blendmode = self.blendmode
          front.auto_clear = {1,1,1,0}

          front:drawTo(function()
              love.graphics.setShader()
              fn()
          end)
          
          love.graphics.setShader(self.shader_info.shader)
          front:draw()
          love.graphics.setShader(last_shader)
          
          love.graphics.setBlendMode(last_blend)
          self.front:release()
      else 
          fn()
      end
  end
}