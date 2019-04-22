package.path = package.path .. ";./?/init.lua"
blanke_path = (...):match("(.-)[^%.]+$")
function blanke_require(import, ignore_errors)
	local status, mod = pcall(require, blanke_path..import)
	if status then return mod elseif not ignore_errors then error(mod) end
	return nil
end

blanke_require('Globals') 
blanke_require('Util')
blanke_require('Debug')
blanke_require('Window')

function _getGameObjects(fn)
	local curr_state = State.current()
	if curr_state then
		fn(curr_state.game)
	else
		fn(StateManager._stray_objects)
	end
end

function _prepareGameObject(obj_type, obj)
    obj.uuid = uuid()
    obj.type = obj_type
    obj.is_instance = true
    obj.pause = ifndef(obj.pause, false)
    obj.persistent = ifndef(obj.persistent, false)
    obj._destroyed = ifndef(obj._destroyed, false)
    obj.net_object = ifndef(obj.net_object, false)
    obj.localOnly = ifndef(obj.localOnly, function(self, fn) fn() end)
    obj._state_created = ifndef(StateManager.current(), {classname=""})
end

function _addGameObject(obj_type, obj)
	_prepareGameObject(obj_type, obj)

    if _G[obj.classname] and _G[obj.classname].instances then 
    	_G[obj.classname].instances:add(obj)
    end
    
    if obj._update or obj.update then obj.auto_update = true end

    -- inject functions xD
    obj._destroyed = false
    if not obj.destroy then
    	obj.destroy = function(self)
	    	_destroyGameObject(obj_type,self)
    		if self.onDestroy then self:onDestroy() end
	    end
    end
    if not obj.netSync then
    	obj.netSync = function(self) end
    end

    _getGameObjects(function(game)
    	game[type] = ifndef(game[type], {})
   		table.insert(game[type], obj)
   	end)
   	
    if BlankE and BlankE._ide_mode then -- (cant access BlankE for some reason)
    	IDE.onAddGameObject(type)
    end
end

function _iterateGameGroup(group, func)
    _getGameObjects(function(game)
		game[group] = ifndef(game[group], {})
	    for i, obj in ipairs(game[group]) do
	        ret_val = func(obj, i, game)
	        if ret_val ~= nil then return ret_val end
	    end
	end)
end

function _destroyGameObject(type, del_obj)
	del_obj._destroyed = true
	if del_obj.draw then del_obj.draw = function() end end
	if del_obj.update then del_obj.update = function(dt) end end

	if del_obj._group and del_obj.uuid ~= nil then
		for g, group in pairs(del_obj._group) do
			group:remove(del_obj)
		end
	end
	_iterateGameGroup(type, function(obj, i, game) 
		if obj.uuid == del_obj.uuid then
			table.remove(game[type],i)
		end
	end)
end	

blanke_require("extra.printr")
--ffmpeg  = blanke_require("extra.ffmpeg")
json 	= blanke_require("extra.json")
uuid 	= blanke_require("extra.uuid")

Class 	= blanke_require('Class')	-- hump.class
Signal 	= blanke_require('Signal')

anim8 	= blanke_require('extra.anim8')
HC 		= blanke_require('extra.HC')
SpatialHash = blanke_require('extra.HC.spatialhash')
blanke_require('extra.noobhub')
--lurker	= blanke_require("extra.lurker")
--lurker.quiet = true

--grease 	= blanke_require('extra.grease')

local modules = {'Group','Repeater','Map','Audio','Asset','Bezier','Camera','Canvas','Dialog','Physics','Font','Draw','Effect','Sprite','Entity','Hitbox','Image','Input','Map','Mask','Net','Save','Scene','State','Steam','Timer','Tween','UI','View'}
-- not required in loop: {'Blanke', 'Globals', 'Util', 'Debug', 'Class', 'doc','conf'}
for m, mod in ipairs(modules) do
	_G[mod] = blanke_require(mod, true)
end
-- loop separately to add other stuff
for m, mod in ipairs(modules) do
	if _G[mod] then 
		if not _G[mod].classname then _G[mod].classname = mod end
		if mod ~= "Group" and not _G[mod].instances then
			_G[mod].instances = Group()
		end
	end
end

Signal.emit('modules_loaded')

-- prevents updating while window is being moved (would mess up collisions)
local max_fps = 120
local min_dt = 1/max_fps
local next_time = love.timer.getTime()

-- inject code into load function
love.load = function(args, unfilteredArgs)
	if BlankE.load then BlankE.load(args, unfilteredArgs) end
	
	local ide = table.hasValue(args, "--ide")
	local record = table.hasValue(args, "--record")
	local play_record = table.hasValue(args, "--play-record")

	if not BlankE.options.debug then BlankE.options.debug = {} end
	BlankE.options.debug.play_record = play_record
	BlankE.options.debug.record = ((record or ide) and not play_record)
	BlankE.options.debug.log = BlankE.options.debug.log or ide 

	BlankE.init()
end

_sleep_timer = 0
function sleep(s)
	_sleep_timer = s
end 

love.run = function()
    if love.math then love.math.setRandomSeed(os.time()) end
    if love.load then love.load(arg) end
    if love.timer then love.timer.step() end

    local dt = 0
    local fixed_dt = 1/60
    local accumulator = 0

    while true do
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == 'quit' then
                    if not love.quit or not love.quit() then
                        return a
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        accumulator = accumulator + dt
        while accumulator >= fixed_dt do
            if love.update then love.update(fixed_dt) end
            accumulator = accumulator - fixed_dt
        end

        if love.graphics and love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())
            love.graphics.origin()
            if love.draw then love.draw() end
            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.0001) end
    end
end

love.quit = function()
	local ret_val = BlankE._quit()
	return ret_val
end


BlankE = {
	_is_init = false,
	_ide_mode = false,
	game_canvas = Canvas(),
	draw_debug = false,

	-- window scaling
	left = 0,
	top = 0,
	right = 0,
	bottom = 0,
	_offset_x = 0,
	_offset_y = 0,
	scale_x = 1,
	scale_y = 1,

	settings = {}, -- game settings from config.json

	_callbacks_replaced = false,
	old_love = {},
	pause = false,
	_class_type = {},
	options = {},
	_options = {
		resolution = Window.resolution,
		plugins={},
		filter="linear",
		scale_mode=Window.scale_mode,
		auto_aspect_ratio=true,
		state='',
		inputs={},
		input={no_repeat={}},
		debug={
			play_record=false,
			record=false,
			log=false
		}
	},
	init = function(in_options)
		if BlankE._is_init then return end

		table.update(BlankE._options, BlankE.options)
		local options = BlankE._options

		-- load plugins
		for p, plugin in ipairs(options.plugins) do
			BlankE.loadPlugin(plugin)
		end

		-- load config file
		if getFileInfo("config.json") then
			BlankE.settings = json.decode(love.filesystem.read('config.json'))
		end

		if not BlankE._callbacks_replaced then
			BlankE._callbacks_replaced = true

			if not BlankE._ide_mode then
				BlankE.injectCallbacks()
			end
		end
		
		-- parsing all options
		if type(options.filter) == "table" then
			Draw.setDefaultFilter(unpack(options.filter))
		else
			Draw.setDefaultFilter(options.filter)
		end

		-- game window size
	    if options.auto_aspect_ratio then
			Window.detectAspectRatio()
		end

	    Window.scale_mode = options.scale_mode
	    local new_w, new_h
		if not Window._res_modified then
			if type(options.resolution) == 'table' then
				Window.setResolution(unpack(options.resolution))
			else
				Window.setResolution(options.resolution)
			end
		end
		new_w, new_h = Window.getResolution()
		BlankE.game_canvas:resize(new_w,new_h)

	    uuid.randomseed(love.timer.getTime()*10000)
	    updateGlobals(0)
	    Asset.add("console.ttf")
	    Draw.setFont("console",24)
	    Debug.setFontSize(18)

		Asset.load()

		-- set inputs
		for i, input in ipairs(options.inputs) do
			Input.set(unpack(input))
		end
		for i, input in ipairs(options.input.no_repeat) do
			Input(input).can_repeat = false
		end 
		Input.set("fullscreen-toggle","lalt-return","ralt-return")
		
		-- debugging 
		BlankE.draw_debug = options.debug.log
		
		if options.debug.play_record then
			Debug.playRecording()
		end
		
		-- automatically load first found state
		if options.state == '' and BlankE._class_type['State'] and BlankE._class_type['State'][1] then
			options.state = BlankE._class_type['State'][1].classname
		end 

		State.switch(options.state)

		if options.debug.record then
			Debug.recordGame()
		end

		BlankE._is_init = true
	end,

	injectCallbacks = function()
		BlankE.old_love = {}
		for fn_name, func in pairs(BlankE) do
			if type(func) == 'function' and fn_name ~= 'init' then
				-- save old love function
				BlankE.old_love[fn_name] = love[fn_name]
				-- inject BlankE callback
				love[fn_name] = function(...)
					if BlankE.old_love[fn_name] then
						BlankE.old_love[fn_name](...)
					end			
					--if fn_name ~= 'quit' then
					--	return BlankE.try(func, ...)
					--else
						return func(...)
					--end
				end
			end
		end
	end,

	try = function(func, ...) -- doesnt rly work
		if func then
			local result, chunk
			result, chunk = xpcall(func, debug.traceback, ...)
			if not result then error(chunk) end
			return result, chunk
		end
	end,

	restoreCallbacks = function()
		for fn_name, func in pairs(BlankE.old_love) do
			love[fn_name] = func
		end
	end,

	getClassList = function(in_type)
		return ifndef(BlankE._class_type[in_type], {})
	end,

	loadPlugin = function(...)
		local plugins = {...}
		for p, plugin in ipairs(plugins) do
			blanke_require('plugins.'..plugin)
		end
	end,

	addClassType = function(in_name, in_type)
		if not _G[in_name] then
			BlankE._class_type[in_type] = ifndef(BlankE._class_type[in_type], {})
			if in_type == 'State' then
				table.insert(BlankE._class_type[in_type], in_name)
				local new_state = Class{__includes=State,
					type = "state",
					classname=in_name,
					auto_update = false,
					_loaded = false,
					_off = true
				}
				StateManager.states[in_name] = new_state
				_G[in_name] = new_state
			end

			if in_type == 'Entity' then	
				table.insert(BlankE._class_type[in_type], in_name)
				_G[in_name] = Class{__includes=Entity,
					type = "entity",
					classname=in_name,
					instances=Group()
				}
			end
		end
	end,

	addEntity = function(in_name) BlankE.addClassType(in_name, 'Entity') end,
	addState  = function(in_name) BlankE.addClassType(in_name, 'State') end,

	restart = function()
		-- restart game I guess?
	end,

	reloadAssets = function()
		-- does this actually do anything?
		require 'assets'
	end,

	clearObjects = function(include_persistent, state)
		state = ifndef(state, StateManager.current_state)

		local game = state.game
		for key, objects in pairs(game) do
			for o, obj in ipairs(objects) do
				if (not obj.persistent) or include_persistent then
					obj:destroy()
					game[key][o] = nil
				end
			end
		end
	end,

	getByUUID = function(type, obj_uuid)
	    _getGameObjects(function(game)
			return _iterateGameGroup(type, function(obj, i)
				if obj.uuid == obj_uuid then
					return game[type][i]
				end
			end)
		end)
	end,

	update = function(dt)
		if lurker then lurker.update() end
	    
	    dt = math.min(dt, min_dt) * dt_mod
	    next_time = next_time + min_dt

		if _sleep_timer > 0 then
			_sleep_timer = _sleep_timer - dt
			return
		end

	    updateGlobals(dt)
	    if UI then UI.update() end
	    BlankE._mouse_updated = false
        Input._releaseCheck()

	    if not BlankE._is_init then return end
	    if Net then Net.update(dt) end
				
    	if not BlankE.pause then
			StateManager.iterateStateStack('update', dt)
		end
		if Debug then Debug.update(dt) end

	    -- default fullscreen toggle shortcut
	    if Input("fullscreen-toggle").released then
	    	Window.toggleFullscreen()
	    end
	end,

	drawToScale = function(func)
    	Draw.translate(BlankE._offset_x, BlankE._offset_y)
    	Draw.scale(BlankE.scale_x, BlankE.scale_y)
		func()
		Draw.reset()
	end,

	draw = function()
		-- draw borders
		Draw.stack(function()
			BlankE.drawOutsideWindow()
			Draw.setColor(Draw.background_color)
			BlankE.drawToScale(function()
				Draw.rect('fill',0,0,game_width,game_height)
			end)
		end)

		-- draw game
		BlankE.game_canvas:drawTo(function()
			StateManager.iterateStateStack('draw')
		end)

		Input.update()

		BlankE.drawToScale(function()
			BlankE.game_canvas:draw(true)
		end)
		if BlankE.draw_debug and Debug then Debug.draw() end

	    local cur_time = love.timer.getTime()
	    if next_time <= cur_time then
	        next_time = cur_time
	        return
	    end
	    love.timer.sleep(next_time - cur_time)
	    
	end,

	drawOutsideWindow = function()
		Draw.setColor('black')
		Draw.rect('fill',0,0,window_width,window_height)
	end,

	scaledMouse = function(x, y) 
		x = (x - BlankE.left) / BlankE.scale_x 
		y = (y - BlankE.top) / BlankE.scale_y

		if x < 0 then x = 0 end
		if y < 0 then y = 0 end
		if x > game_width then x = game_width end
		if y > game_height then y = game_height end

		return x, y 
	end,

	resize = function(w,h)
		_iterateGameGroup("effect", function(effect)
			effect:resizeCanvas(w, h)
		end)
		window_width = w 
		window_height = h
	end,
--[[
	keypressed = function(key) Input.keypressed(key) end,
	keyreleased = function(key) Input.keyreleased(key) end,
	mousepressed = function(x, y, button) 
	    x, y = BlankE.scaledMouse(x, y)
	    Input.mousepressed(x, y, button)
	end,
	mousereleased = function(x, y, button) Input.mousereleased(x, y, button) end,
	wheelmoved = function(x, y) Input.wheelmoved(x, y) end,
    joystickpressed = function(joy,btn) Input.joystickreleased(joy, btn) end,
    joystickreleased = function(joy,btn) Input.joystickreleased(joy, btn) end,
	gamepadreleased = function(joy, btn) Input.gamepadreleased(joy, btn) end,
	]]
	_quit = function()
		if BlankE.quit and BlankE.quit() then return true end

	    if Net then Net.disconnect() end
		if Debug then Debug.quit() end
		
		return false
	end,

	errorhandler = function(msg)
		print(debug.traceback("Error: " .. tostring(msg), 10):gsub("\n[^\n]+$", ""))
	end,
}

local old_errorhandler = love.errorhandler
love.errorhandler = BlankE.errorhandler

return BlankE