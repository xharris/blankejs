local stack = {} -- { }
CanvasStack = class{
    getCanvas = function(self)
        if not self.canvas then 
            local found = false 
            -- recycle a canvas
            for c, canv in ipairs(stack) do 
                if not canv._used then 
                    self.canvas = canv
                    found = true
                end 
            end 
            -- add a new canvas
            if not found then 
                self.canvas = Canvas()
                self.canvas:remDrawable()
                table.insert(stack, self.canvas)
            end
            self.canvas._used = true
        end
        return self.canvas
    end,
    drawTo = function(self, fn)
        self.canvas:drawTo(fn)
    end,
    draw = function(self)   
        if self.quad then self.canvas.quad = self.quad end  
        self.canvas:draw()  
    end,
    release = function(self)
        self.canvas._used = false
        self.canvas:reset()
        self.canvas = nil
    end
}

System{
    'canvas',
    add = function(obj)

    end,
}