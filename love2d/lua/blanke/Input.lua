--[[

GameCube
1 - Y
2 - A 
3 - B 
4 - X
5 - L
6 - R
8 - Z
10 - Start
13 - D Up
14 - D Right
15 - D Down
16 - D Left

]]--

function love.keypressed(key) Input.keypressed(key) end
function love.keyreleased(key) Input.keyreleased(key) end
function love.mousepressed(x, y, button) 
    x, y = BlankE.scaledMouse(x, y)
    Input.mousepressed(x, y, button)
end
function love.mousereleased(x, y, button) Input.mousereleased(x, y, button) end
function love.wheelmoved(x, y) Input.wheelmoved(x, y) end
function love.joystickpressed(joy,btn) Input.joystickpressed(joy, btn) end
function love.joystickreleased(joy,btn) Input.joystickreleased(joy, btn) end
function love.gamepadreleased(joy, btn) Input.gamepadreleased(joy, btn) end

local c = getFileInfo("gamecontrollerdb.txt")
if c then 
    love.joystick.loadGamepadMappings("gamecontrollerdb.txt")
end 

_Input = Class{
	init = function(self, ...)
        self.in_key = {}
        self.multi_key = {}
        self.is_multi_key = {}
        self.in_mouse = {}
        self.in_region = {}
        self.in_pad = {}

        self.onInput = nil
        self._on = false -- are any of the inputs active?
        self._reset_wheel = false
        self.persistent = true

        self.press_count = 0
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

        elseif input:starts("pad") then
            local pad = input:split(".")[2]
            self:addMultikey(pad,'pad')

        else -- regular keyboard input
            self:addMultikey(input,'key')
        
        end
        return self
	end,
    
    remove = function(self, input)
        if input:starts("mouse") then
            local btn = input:split(".")[2]
            self.in_mouse[input] = nil
        
        elseif input:starts("pad") then
            local pad = input:split(".")[2]
            self.in_pad[pad] = nil
            self:removeMultikey(input)

        else -- regular keyboard input
            self.in_key[input] = nil
            self:removeMultikey(input)
            
        end
        return self
    end,

    addRegion = function(self, shape_type, ...)
        local other_args = {...}
        return Input
    end,

    addMultikey = function(self, input, input_type)
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
        self["in_"..input_type][input] = 0 --cond(love.keyboard.isDown(ifndef(btn, input)), 1, 0)
    end,

    removeMultikey = function(self, input)
        self.is_multi_key[input] = false
    end,

    pressMultikey = function(self, key,in_type)
        for input,_ in pairs(self.multi_key[key]) do
            self["in_"..in_type][input] = self["in_"..in_type][input] + 1

            -- only press if all keys are down
            if self["in_"..in_type][input] == input:count("-")+1 then
                self:press()
            end
        end
    end,

    releaseMultikey = function(self, key,in_type)
        for input,_ in pairs(self.multi_key[key]) do
            self["in_"..in_type][input] = self["in_"..in_type][input] - 1

            -- only press if all keys are down
            if self["in_"..in_type][input] == input:count("-") then
                self:release()
            end
        end
    end,

    isMultikey = function(self, key)
        return self.multi_key[key]
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

    update = function(self, dt)
        if self.pressed then
            -- can repeat?
            if not self.can_repeat and self.press_count > 1 then
                self.pressed = false
            end 
            self.press_count = self.press_count + 1
        end
    end,

    -- a mouse/keyboard input has been pressed
    press = function(self)
        self.pressed = true
        self.released = false
        self._release_checked = false
        self.press_count = self.press_count + 1
    end,

    -- a mouse/keyboard input has been released
    release = function(self)
        self.pressed = false
        self.released = true
        self._release_checked = false
        self.press_count = 0
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
    controllers = {},
    controller = nil,
    deadzone = 0,

    set = function(name, ...)
        local new_input = _Input(...)
        new_input.persistent = true
        Input.keys[name] = new_input
        new_input.name = name
        return Input
    end,

    setController = function(id)
        if Input.controllers[id] ~= nil then
            Input.controller = Input.controllers[id]
        end
    end,

    getAxis = function(i)
        if Input.controller then 
            i = clamp(i,1,Input.controller.axisCount)
            local axis = Input.controller._joy:getAxis(i)
            return cond(math.abs(axis) > Input.deadzone, axis, 0)
        end
        return 0
    end,

    setVibration = function(left,right,duration)
        if Input.controller then
            return Input.controller._joy:setViration(left,right,duration)
        end 
    end,
    getVibration = function()
        if Input.controller then
            return Input.controller._joy:getViration()
        end 
    end,

    simulateKeyPress = function(key) Input.keypressed(key) end,
    simulateKeyRelease = function(key) Input.keyreleased(key) end,
    simulateMousePress = function(x,y,button) Input.mousereleased(x,y,button) end,
    simulateMouseRelease = function(x,y,button) Input.mousepressed(x,y,button) end,

    keypressed = function(key)
        Input.last_key = key
        Signal.emit('keypress',key)
        for o, obj in pairs(Input.keys) do
            if obj.in_key[key] ~= nil or obj:isMultikey(key) then

                if obj:isMultikey(key) then
                    obj:pressMultikey(key,'key')
                else
                    -- single key press
                    obj.in_key[key] = obj.in_key[key] + 1
                    obj:press()
                end

            end
        end
        return Input
    end,
    
    keyreleased = function(key)
        Signal.emit('keyrelease',key)
        for o, obj in pairs(Input.keys) do
            if obj.in_key[key] ~= nil or obj:isMultikey(key) then

                if obj:isMultikey(key) then
                    obj:releaseMultikey(key,'key')
                else
                    -- single key release
                    obj.in_key[key] = 0;
                    obj:release()
                end
            end
        end
        return Input
    end,
    
    mousepressed = function(x, y, button)
        Signal.emit('mousepress',x,y,button)
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
        Signal.emit('mouserelease',x,y,button)
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

    joystickpressed = function(joy,btn)
        if joy:getID() ~= Input.controller.id then return end
        btn = tostring(btn)
        for o, obj in pairs(Input.keys) do
            if obj.in_pad[btn] ~= nil or obj:isMultikey(btn) then

                if obj:isMultikey(btn) then
                    obj:pressMultikey(btn,'pad')
                else
                    -- single key press
                    obj.in_pad[btn] = obj.in_pad[btn] + 1
                    obj:press()
                end

            end
        end
        return Input
    end,

    joystickreleased = function(joy,btn)
        if joy:getID() ~= Input.controller.id then return end
        btn = tostring(btn)
        for o, obj in pairs(Input.keys) do
            if obj.in_pad[btn] ~= nil or obj:isMultikey(btn) then

                if obj:isMultikey(btn) then
                    obj:releaseMultikey(btn,'pad')
                else
                    -- single key release
                    obj.in_pad[btn] = 0
                    obj:release()
                end

            end
        end
        return Input
    end,

    gamepadpressed = function(joy, btn)
        --local inputtype, inputindex, hatdirection = joystick:getGamepadMapping(button)
    end,

    gamepadreleased = function(joy, btn)

    end,

    update = function()
        for o, obj in pairs(Input.keys) do
            for input, val in pairs(obj.in_key) do
                if not obj.is_multi_key[input] and obj.in_key[input] > 0 then obj.in_key[input] = obj.in_key[input] + 1 end
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

function love.joystickadded(joy)
    Signal.emit('controlleradded',joy:getID())
    Input.controllers[joy:getID()] = {
        _joy = joy,
        id = joy:getID(),
        name = joy:getName(),
        axisCount = joy:getAxisCount(),
        canVibrate = joy:isVibrationSupported()
    }
    if Input.controller == nil then 
        Input.setController(joy:getID())
    end
end

function love.joystickremoved(joy)
    Signal.emit('controllerremoved',joy:getID())
    Input.controllers[joy:getID()] = nil
end

return Input