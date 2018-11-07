Canvas = Class{
    last_active = nil,
    init = function(self, width, height)
        self.canvas = love.graphics.newCanvas(width, height)
        self.width = self.canvas:getWidth()
        self.height = self.canvas:getHeight()
        
        self.active = false
        self.auto_clear = true
        --self.clear_color = {1,1,1,0}
        self._prev_canvas = nil
        
        _addGameObject('canvas',self)
    end,

    __eq = function(self, other)
        return (self.uuid == other.uuid)
    end,
    
    resize = function(self, w, h)
        self.canvas = love.graphics.newCanvas(width, height)
    end,

    start = function(self)
        self.active = true
        self._prev_canvas = Canvas.last_active
        Canvas.last_active = self

        love.graphics.setCanvas{self.canvas, stencil=true}
        if self.auto_clear then
            love.graphics.clear({1,1,1,0})
        end
    end,
    
    stop = function(self)
        self.active = false
        if self.last_active == self then
            self.last_active = nil
        end
        love.graphics.setCanvas(self._prev_canvas)
    end,
    
    drawTo = function(self, func)
        self:start()
        func()
        self:stop()
    end,
    
    draw = function(self, ...)
        love.graphics.draw(self.canvas, ...)
    end,
}

return Canvas