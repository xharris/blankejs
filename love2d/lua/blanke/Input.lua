_Input = Class{
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

    
    addRegion = function(shape_type, ...)
        local other_args = {...}
        return Input
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

Input = {
    keys = {},

    set = function(name, ...)
        local new_input = _Input(...)
        new_input.persistent = true
        Input.keys[name] = new_input
        return Input
    end,    
    
    keypressed = function(key)
        for o, obj in pairs(Input.keys) do
            if obj.in_key[key] ~= nil then obj.in_key[key] = true end
        end
        return Input
    end,
    
    keyreleased = function(key)
        for o, obj in pairs(Input.keys) do
            if obj.in_key[key] ~= nil then obj.in_key[key] = false; obj.pressed = false end
        end
        return Input
    end,
    
    mousepressed = function(x, y, button)
        local btn_string = "mouse." .. button
        for o, obj in pairs(Input.keys) do
            if obj.in_mouse[btn_string] ~= nil then obj.in_mouse[btn_string] = true end
            
            local region = obj:getRegion(x, y)
            if region ~= nil then
                region = true
            end
        end
        return Input
    end,
    
    mousereleased = function(x, y, button)
        local btn_string = "mouse." .. button
        for o, obj in pairs(Input.keys) do
            if obj.in_mouse[btn_string] ~= nil then obj.in_mouse[btn_string] = false end
            
            local region = obj:getRegion(x, y)
            if region ~= nil then
                region = false
            end
            obj.pressed = false
        end
        return Input
    end,

    wheelmoved = function(self, x, y)
        local dir_strings = {
            ['wheel.up']    = y>0 and y or 0,
            ['wheel.down']  = y<0 and y or 0,
            ['wheel.right'] = x>0 and x or 0,
            ['wheel.left']  = x<0 and x or 0
        }

        for o, obj in pairs(Input.keys) do
            for dir, value in pairs(obj.in_mouse) do
                if dir_strings[dir] ~= nil then
                    obj._reset_wheel = true
                    obj.in_mouse[dir] = dir_strings[dir]
                end
            end
        end
    end,

    reset = function(key)
        Input.key[key]:reset()
        return Input
    end,

    mt = {
        __index = function(self, key)
            return Input.keys[key]
        end,

        __call = function(self, ...)
            local ret_val = false
            local args = {...}
            for a, arg in pairs(args) do
                if Input.keys[arg]() then
                    ret_val = true
                end
            end
            return ret_val
        end
    }
}

setmetatable(Input, Input.mt)

return Input