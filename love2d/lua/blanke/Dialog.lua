Dialog = Class{
	init = function (self, x, y, width)
        self.x = ifndef(x,0)
        self.y = ifndef(y,0)
        self.width = ifndef(width, game_width - x)
        
        self.type = "normal" -- normal, typewriter
        self.font_size = 12
        self.text_speed = 20
        self.align = "left"
        self.delay = 2
        
        self.texts = {}
        self.text_char = 1
        
        self.timer = Timer.new()
        self.font_obj = love.graphics.newFont(self.font_size)
        self.text_obj = love.graphics.newText(self.font_obj)

        _addGameObject('dialog',self)
    end,
    
    update = function(self, dt)
        self.timer:update(dt)
        return self
    end,
    
    draw = function(self)
        love.graphics.draw(self.text_obj, self.x, self.y)
        return self
    end,
    
    setFont = function(self, new_font)
        self.font_obj = new_font
        return self
    end,    
    
    addText = function(self, text)
        table.insert(self.texts, text)
        return self
    end,
    
    _resetPrintVars = function(self)
        self.text_index = 1
        self.text_char = 1
        return self
    end,
    
    _normal = function(self, str, isPlayAll)
        str = self.texts[1]
        self.text_obj:setf(str, self.width, self.align)
        table.remove(self.texts, 1)

        if isPlayAll and #self.texts > 0 then
            -- show next text after delay
            self.timer:after(self.delay, function()
                self:_normal("", isPlayAll)
            end)
        else
            -- set text to nothing
            self.timer:after(self.delay, function() self:reset() end)
        end
        return self
    end,
    
    _typewriter = function(self, str, isPlayAll)        
        -- display the new string
        self.text_obj:setf(str, self.width, self.align)
        
        if #str < #self.texts[1] then
            self.timer:after(self.text_speed/1000, function()
                local extra_txt = str .. self.texts[1]:sub(self.text_char, self.text_char)
                self.text_char = self.text_char + 1
                self:_typewriter(extra_txt, isPlayAll)
            end)
        else
            table.remove(self.texts, 1)

            if isPlayAll and #self.texts > 0 then
                -- show next text after delay
                self.timer:after(self.delay, function()
                    self.text_char = 1
                    self:_typewriter("", isPlayAll)
                end)
            else
                -- set text to nothing
                self.timer:after(self.delay, function() self:reset() end)
            end
            
        end
        return self
    end,
    
    step = function(self)
        self:_resetPrintVars()
        self["_" .. self.type](self, "", false)
        return self
    end,
    
    play = function(self)
        self:_resetPrintVars()
        self["_" .. self.type](self, "", true)
        return self
    end,
    
    -- remove all dialogs
    reset = function(self)
        self.texts = {}
        self.text_obj:set("")
        self:_resetPrintVars()
        return self
    end
}

return Dialog