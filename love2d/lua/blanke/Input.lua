_Input = Class{
	init = function(self, ...)
        self.in_key = {}
        self.multi_key = {}
        self.is_multi_key = {}
        self.in_mouse = {}
        self.in_region = {}

        self.onInput = nil
        self._on = false -- are any of the inputs active?
        self._reset_wheel = false
        self.persistent = true

        -- implement later
        self.pressed = false
        self.released = false
        self._release_checked = false

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
            self.in_mouse[input] = 0
        elseif input == 'region' then
            self:addRegion(...)

        else -- regular keyboard input
            local multi_key = input:split("-")
            if #multi_key > 1 then
                -- key is only ON when all keys in this list are pressed
                for i,key in ipairs(multi_key) do
                    -- add a reference (key -> input_str)
                    if not self.multi_key[key] then
                        self.multi_key[key] = {}
                    end
                    self.multi_key[key][input] = true
                end
                self.is_multi_key[input] = true
            end
            self.in_key[input] = 0 --cond(love.keyboard.isDown(ifndef(btn, input)), 1, 0)
        end
        return self
	end,
    
    remove = function(self, input)
        if input:starts("mouse") then
            local btn = input:split(".")[2]
            self.in_mouse[input] = nil
        
        else -- regular keyboard input
            self.in_key[input] = nil
            self.is_multi_key[input] = false
            
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
    end, 
    
    getRegion = function(self, x, y)
        return nil
    end,

    -- a mouse/keyboard input has been pressed
    press = function(self, name)
        self.pressed = true
        self.released = false
        self._release_checked = false

        if Debug._input then Debug._input("press",name)
    end,

    -- a mouse/keyboard input has been released
    release = function(self, name)
        self.pressed = false
        self.released = true
        self._release_checked = false

        if Debug._input then Debug._input("release",name)
    end,

    -- check if .release value should be reset
    releaseCheck = function(self)
        if self._release_checked then self.released = false 
        else self._release_checked = true end
    end,

    _isOn = function(self)
        if not self.can_repeat and self.pressed then return false end

        local ret_val = {}
        local last_val = nil
        function addRet(input_name, value)
            last_val = value
            ret_val[input_name] = value
        end

        for input, val in pairs(self.in_key) do
            if val > 0 then self.pressed = true; addRet(input, val) end
        end
        
        for input, val in pairs(self.in_mouse) do
            if input:starts("wheel") and val ~= 0 then
                self.in_mouse[input] = 0
                return val
            elseif val > 0 then self.pressed = true; addRet(input, val) end
        end
        
        for input, val in pairs(self.in_region) do
            if val == true then self.pressed = true; return true end
        end

        if not last_val then
            return 0
        elseif table.len(ret_val) == 1 then
            if last_val == 0 then
                return 0
            else
                return last_val
            end
        else
            return ret_val
        end
    end,
    
    __call = function(self)
        return self:_isOn()
    end
}

Input = {
    keys = {},
    last_key='',

    set = function(name, ...)
        local new_input = _Input(...)
        new_input.persistent = true
        Input.keys[name] = new_input
        return Input
    end,    
    
    keypressed = function(key)
        Input.last_key = key
        for o, obj in pairs(Input.keys) do
            if obj.in_key[key] ~= nil or obj.multi_key[key] then

                if obj.multi_key[key] then
                    for input,_ in pairs(obj.multi_key[key]) do
                        obj.in_key[input] = obj.in_key[input] + 1

                        -- only press if all keys are down
                        if obj.in_key[input] == input:count("-")+1 then
                            obj:press(input)
                        end
                    end
                else
                    -- single key press
                    obj.in_key[key] = obj.in_key[key] + 1
                    obj:press(key)
                end

            end
        end
        return Input
    end,
    
    keyreleased = function(key)
        for o, obj in pairs(Input.keys) do
            if obj.in_key[key] ~= nil or obj.multi_key[key] then

                if obj.multi_key[key] then
                    for input,_ in pairs(obj.multi_key[key]) do
                        obj.in_key[input] = obj.in_key[input] - 1

                        -- only press if all keys are down
                        if obj.in_key[input] == input:count("-") then
                            obj:release(input)
                        end
                    end
                else
                    -- single key release
                    obj.in_key[key] = 0;
                    obj:release(key)
                end
            end
        end
        return Input
    end,

    update = function()
        for o, obj in pairs(Input.keys) do
            for input, val in pairs(obj.in_key) do
                if not obj.is_multi_key[input] and obj.in_key[input] > 0 then obj.in_key[input] = obj.in_key[input] + 1 end
            end
        end
    end,
    
    mousepressed = function(x, y, button)
        local btn_string = "mouse." .. button
        for o, obj in pairs(Input.keys) do
            if obj.in_mouse[btn_string] ~= nil then
                obj:press()
            end
            
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
            if obj.in_mouse[btn_string] ~= nil then
                obj:release()
            end
            
            local region = obj:getRegion(x, y)
            if region ~= nil then
                region = false
            end
        end
        return Input
    end,

    wheelmoved = function(self, x, y)
        if not x then x = 0 end
        if not y then y = 0 end
        
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

    _releaseCheck = function()
        for k, obj in pairs(Input.keys) do
            obj:releaseCheck()
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
            local ret_val = nil
            local args = {...}
            for a, arg in pairs(args) do
                if Input.keys[arg] then
                    ret_val = Input.keys[arg]
                end
            end
            assert(ret_val, 'Input not found: \"'..tostring(...)..'\"')
            return ret_val
        end
    }
}

setmetatable(Input, Input.mt)

return Input