Canvas = Class{
    last_active = nil,
    init = function(self, width, height)
        width = ifndef(width, game_width)
        height = ifndef(height, game_height)

        self.canvas = love.graphics.newCanvas(width, height)
        self.canvas:setFilter("nearest", "nearest")
        self.width = self.canvas:getWidth()
        self.height = self.canvas:getHeight()
        
        self.active = false
        self.auto_clear = true
        self.clear_color = nil
        self._prev_canvas = nil
        
        _addGameObject('canvas',self)
    end,

    __eq = function(self, other)
        return (self.uuid == other.uuid)
    end,
    
    resize = function(self, w, h)
        self.canvas = love.graphics.newCanvas(w, h)
        self.width = self.canvas:getWidth()
        self.height = self.canvas:getHeight()
    end,

    drawTo = function(self, func)
        self._prev_canvas = love.graphics.getCanvas()
        love.graphics.setCanvas{self.canvas, stencil=true}
        if self.auto_clear then
            love.graphics.clear(self.clear_color)
        end
        func()
        love.graphics.setCanvas(self._prev_canvas)
    end,
    
    draw = function(self, ...)
        love.graphics.draw(self.canvas, ...)
    end,
}

return Canvas