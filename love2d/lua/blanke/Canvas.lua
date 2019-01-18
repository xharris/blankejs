Canvas = Class{
    last_active = nil,
    init = function(self, width, height)
        width = ifndef(width, game_width)
        height = ifndef(height, game_height)

        self.canvas = love.graphics.newCanvas(width, height)
        --self.canvas:setFilter("nearest", "nearest")
        self.width = self.canvas:getWidth()
        self.height = self.canvas:getHeight()
        self.blend_mode = {"alpha","premultiplied"}

        self.active = false
        self.auto_clear = true
        self.clear_color = nil
        self._prev_canvas = nil
        
        _addGameObject('canvas',self)

        --self.clear_color = Draw._parseColorArgs(self._state_created.background_color)
        --self.clear_color[4] = 0
    end,

    __eq = function(self, other)
        return (self.uuid == other.uuid)
    end,
    
    resize = function(self, w, h)
        self.canvas = love.graphics.newCanvas(w, h)
        self.width = self.canvas:getWidth()
        self.height = self.canvas:getHeight()
    end,

    _applied = 0,
    drawTo = function(self, func)
        self._prev_canvas = love.graphics.getCanvas()

        Draw.stack(function()
            love.graphics.setCanvas{self.canvas, stencil=true}
            if self.auto_clear then
                love.graphics.clear(self.clear_color)
            end
            love.graphics.origin()
            Canvas._applied = Canvas._applied + 1
            if View._transform and Canvas._applied > 1 then
                love.graphics.replaceTransform(View._transform)
            end
            love.graphics.setBlendMode("alpha")
            func()
        end)
        love.graphics.setCanvas(self._prev_canvas)
        Canvas._applied = Canvas._applied - 1
    end,
    
    draw = function(self, is_main_canvas)
        if not is_main_canvas then
            Draw.push()
            love.graphics.origin()
        end
        love.graphics.setBlendMode(unpack(self.blend_mode))
        love.graphics.draw(self.canvas)
        if not is_main_canvas then
            Draw.pop()
        end
    end,
}

return Canvas