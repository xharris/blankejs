Canvas = Class{
    init = function(self)
        self.canvas = love.graphics.newCanvas()
        self.width = self.canvas:getWidth()
        self.height = self.canvas:getHeight()
        
        self.auto_clear = true
        
        self._prev_canvas = nil
        
        _addGameObject('canvas',self)
    end,
    
    start = function(self)
        --self._prev_canvas = love.graphics.getCanvas()
        love.graphics.setCanvas(self.canvas)
        if self.auto_clear then
            love.graphics.clear()
        end
    end,
    
    stop = function(self)
        love.graphics.setCanvas()--self._prev_canvas)
    end,
    
    drawTo = function(self, func)
        self:start()
        func()
        self:stop()
    end,
    
    draw = function(self)
        love.graphics.draw(self.canvas)
    end,
}

return Canvas