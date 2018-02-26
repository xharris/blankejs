Input = Class{
    global_keys = {},

	init = function(self, ...)
        self.in_key = {}
        self.in_mouse = {}
        self.in_region = {}

        self.onInput = nil
        self._on = false -- are any of the inputs active?
        self._reset_wheel = false

        -- implement later
        self.pressed = false
        self.released = false

        self.can_repeat = true

		-- store inputs
		arg_inputs = {...}
		for i_in, input in ipairs(arg_inputs) do
			self:add(input)
		end

        _addGameObject('input',self)
	end,

	add = function(self, input, ...)
        if input:starts("mouse") or input:starts("wheel") then
            local btn = input:split(".")[2]
            self.in_mouse[input] = false
        elseif input == 'region' then
            self:addRegion(...)

        else -- regular keyboard input
            self.in_key[input] = love.keyboard.isDown(ifndef(btn, input))
            
        end
        return self
	end,
    
    remove = function(self, input)
        if input:starts("mouse") then
            local btn = input:split(".")[2]
            self.in_mouse[input] = nil
        
        else -- regular keyboard input
            self.in_key[input] = nil
            
        end
        return self
    end,

    setGlobal = function(name, ...)
        local new_input = Input(...)
        new_input.persistent = true
        Input.global_keys[name] = new_input
        return Input
    end,

    global = function(name)
        return Input.global_keys[name]()
    end,
    
    addRegion = function(self, shape_type, ...)
        local other_args = {...}
        return self
    end,
    
    keypressed = function(self, key)
        if self.in_key[key] ~= nil then self.in_key[key] = true end
        return self
    end,
    
    keyreleased = function(self, key)
        if self.in_key[key] ~= nil then self.in_key[key] = false end
        self.pressed = false
        return self
    end,
    
    mousepressed = function(self, x, y, button)
        local btn_string = "mouse." .. button
        if self.in_mouse[btn_string] ~= nil then self.in_mouse[btn_string] = true end
        
        local region = self:getRegion(x, y)
        if region ~= nil then
            region = true
        end
        return self
    end,
    
    mousereleased = function(self, x, y, button)
        local btn_string = "mouse." .. button
        if self.in_mouse[btn_string] ~= nil then self.in_mouse[btn_string] = false end
        
        local region = self:getRegion(x, y)
        if region ~= nil then
            region = false
        end
        self.pressed = false
        return self
    end,

    wheelmoved = function(self, x, y)
        local dir_strings = {
            ['wheel.up']    = y>0 and y or 0,
            ['wheel.down']  = y<0 and y or 0,
            ['wheel.right'] = x>0 and x or 0,
            ['wheel.left']  = x<0 and x or 0
        }
        
        for dir, value in pairs(self.in_mouse) do
            if dir_strings[dir] ~= nil then
                self._reset_wheel = true
                self.in_mouse[dir] = dir_strings[dir]
            end
        end
    end,

    reset = function(self)
        if self._reset_wheel then
            for dir, value in pairs(self.in_mouse) do
                if dir:starts("wheel") then
                    self.in_mouse[dir] = 0
                end
            end
            self._reset_wheel = false
        end
        self.pressed = false
    end,
    
    getRegion = function(self, x, y)
        return nil
    end,

    _isOn = function(self)
        if not self.can_repeat and self.pressed then return false end

        for input, val in pairs(self.in_key) do
            if val == true then self.pressed = true; return true end
        end
        
        for input, val in pairs(self.in_mouse) do
            if input:starts("wheel") and val ~= 0 then
                self.in_mouse[input] = 0
                return val
            elseif val == true then self.pressed = true; return true end
        end
        
        for input, val in pairs(self.in_region) do
            if val == true then self.pressed = true; return true end
        end

        return false
    end,
    
    __call = function(self)
        return self:_isOn()
    end
}

return Input