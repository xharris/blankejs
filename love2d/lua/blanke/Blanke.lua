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

local modules = {'Group','Repeater','Map','Audio','Asset','Bezier','Camera','Canvas','Dialog','Font','Draw','Effect','Sprite','Entity','Hitbox','Image','Input','Map','Mask','Net','Save','Scene','State','Steam','Timer','Tween','UI','View'}
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
Physics = love.physics

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

	if BlankE.options.debug then
		BlankE.options.debug.play_record = play_record
		BlankE.options.debug.record = ((record or ide) and not play_record)
		if not ide then BlankE.options.debug.log = false end
	end

	BlankE.init()
end
--[[
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
end]]

love.quit = function()
	local ret_val = BlankE._quit()
	return ret_val
end


BlankE = {
	_is_init = false,
	_ide_mode = false,
	show_grid = true,
	snap = {32, 32},
	grid_color = {255,255,255},
	_offx = 0,
	_offy = 0,
	_stencil_offset = 0,
	_snap_mouse_x = 0,
	_snap_mouse_y = 0,
	_mouse_x = 0,
	_mouse_y = 0,
	game_canvas = Canvas(800,600),
	draw_debug = false,

	-- window scaling
	left = 0,
	top = 0,
	right = 0,
	bottom = 0,
	_offset_x = 0,
	_offset_y = 0,
	_upscaling = 1,
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
			love.graphics.setDefaultFilter(unpack(options.filter))
		else
			love.graphics.setDefaultFilter(options.filter, options.filter)
		end

		-- game window size
	    if options.auto_aspect_ratio then
			Window.detectAspectRatio()
		end

	    Window.scale_mode = options.scale_mode
	    local new_w, new_h
	    if not Window._res_modified then
			Window.setResolution(options.resolution)
		end
		new_w, new_h = Window.getResolution()
		BlankE.game_canvas:resize(new_w,new_h)

	    uuid.randomseed(love.timer.getTime()*10000)
	    updateGlobals(0)
	    Asset.add("console.ttf")
	    Draw.setFont("console",24)

		Asset.load()

		-- set inputs
		for i, input in ipairs(options.inputs) do
			Input.set(unpack(input))
		end
		Input.set("fullscreen-toggle","lalt-return","ralt-return")
		
		-- debugging 
		BlankE.draw_debug = options.debug.log
		
		if options.debug.play_record then
			Debug.playRecording()
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
		require 'assets'
	end,

	getCurrentState = function()
		local state = State.current()
		if type(state) == "string" then
			return state
		end
		if type(state) == "table" then
			return state.classname
		end
		return state
	end,

	clearObjects = function(include_persistent, state)
	    if state then
	    	local game = state.game
			for key, objects in pairs(game) do
				for o, obj in ipairs(objects) do
					if (not obj.persistent) or include_persistent then
						obj:destroy()
						game[key][o] = nil
					end
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

	getInstances = function(type)
		local classname = _G[type].classname
		local ret_instances = {}
		_iterateGameGroup(type, function(obj, i)
			if obj.classname == classname then
				table.insert(ret_instances, obj)
			end
		end)
		return ret_instances
	end,

	main_cam = nil,
	snap = {32,32},
	initial_cam_pos = {0,0},

	_getSnap = function() 
		local zoom_amt = 1
		local snap = ifndef(BlankE.snap, {32,32})
		snap[1] = snap[1] * zoom_amt
		snap[2] = snap[2] * zoom_amt
		return snap
	end,

	_grid_x = 0,
	_grid_y = 0,
	_grid_width = 0,
	_grid_height = 0,

	_drawGrid = function(x, y, width, height)	
		local grid_color = BlankE.grid_color

		-- outside view line
		love.graphics.push('all')
		love.graphics.setColor(grid_color[1], grid_color[2], grid_color[3], 15)
		
		BlankE._drawGridFunc(x, y, width, height)

		-- in-view lines
		for o = 0,2,1 do
			BlankE._stencil_offset = -o

    		love.graphics.setColor(grid_color[1], grid_color[2], grid_color[3], 1)
    		BlankE._grid_x = x
    		BlankE._grid_y = y
    		BlankE._grid_width = width
    		BlankE._grid_height = height
    		love.graphics.stencil(BlankE._gridStencilFunction, "replace", 1)
		 	love.graphics.setStencilTest("greater", 0)
		 	BlankE._drawGridFunc(x, y, width, height)
    		love.graphics.setStencilTest()
		end
		love.graphics.pop()
	end,

	_gridStencilFunction = function()
		local conf_w, conf_h = CONF.window.width, CONF.window.height --game_width, game_height

		local rect_x = (BlankE._grid_width/2)-(conf_w/2)
		local rect_y = (BlankE._grid_height/2)-(conf_h/2)

		local g_x, g_y = BlankE._grid_x, BlankE._grid_y

	   	love.graphics.rectangle("fill",
	   		rect_x+g_x-(BlankE._grid_width/2)+BlankE._stencil_offset,
	   		rect_y+g_y-(BlankE._grid_height/2)+BlankE._stencil_offset,
	   		conf_w+BlankE._stencil_offset,
	   		conf_h+BlankE._stencil_offset
	   	)
	end,

	_drawGridFunc = function(x, y, width, height)
		if not (BlankE.show_grid and BlankE._ide_mode) then return BlankE end

		local snap = BlankE._getSnap()
		local grid_color = BlankE.grid_color

		local conf_w = CONF.window.width
		local conf_h = CONF.window.height

		local diff_w = ((game_width) - (conf_w))
		local diff_h = ((game_height) - (conf_h))

		local half_height = height/2
		local half_width = width/2

		-- resizing the window offset
		x = x - math.abs(diff_w)
		y = y - math.abs(diff_h)
		width = width + math.abs(diff_w*2)
		height = height + math.abs(diff_h*2)

		local x_offset = -((x-half_width) % snap[1])
		local y_offset = -((y-half_height) % snap[2])

		local min_grid_draw = 8

		love.graphics.push('all')
		love.graphics.setLineStyle("rough")
		--love.graphics.setBlendMode('replace')

		-- draw origin
		love.graphics.setLineWidth(3)
		love.graphics.setColor(grid_color[1], grid_color[2], grid_color[3], 15)
		love.graphics.line(x-half_width, 0, x+width-half_width, 0) -- vert
		love.graphics.line(0, y-half_height, 0, y+height-half_height)  -- horiz		
		love.graphics.setLineWidth(1)

		-- vertical lines
		if snap[1] >= min_grid_draw then
			for g_x = x-half_width,x+width,snap[1] do
				love.graphics.line(g_x + x_offset, y - half_height, g_x + x_offset, y + height - half_height)
			end
		end

		-- horizontal lines
		if snap[2] >= min_grid_draw then
			for g_y = y-half_height,y+height,snap[2] do
				love.graphics.line(x - half_width, g_y + y_offset, x + width - half_width, g_y + y_offset)
			end
		end
		love.graphics.pop()

		return BlankE
	end,

	setGridSnap = function(snapx, snapy)
		BlankE.snap = {snapx, snapy}
	end,

	updateGridColor = function()
		-- make grid color inverse of background color
		local r,g,b,a = love.graphics.getBackgroundColor()
	    r = 255 - r; g = 255 - g; b = 255 - b;
		BlankE.grid_color = {r,g,b}		
	end,

	update = function(dt)
		if lurker then lurker.update() end
	    
	    dt = math.min(dt, min_dt) * dt_mod
	    next_time = next_time + min_dt

	    -- BlankE.updateGridColor()

		-- calculate grid offset
		local snap = BlankE._getSnap()

		local g_x, g_y = 0,0

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
		if not BlankE._mouse_updated then
			BlankE._mouse_x, BlankE._mouse_y = mouse_x, mouse_y
		end

	end,

	drawToScale = function(func)
    	Draw.translate(math.floor(BlankE._offset_x * BlankE.scale_x), math.floor(BlankE._offset_y * BlankE.scale_y))
    	Draw.scale(BlankE.scale_x, BlankE.scale_y)

		func()

		Draw.reset()
	end,

	reapplyScaling = function()
		Draw.scale(BlankE.scale_x, BlankE.scale_y)
		Draw.translate(BlankE._offset_x, BlankE._offset_y)	
	end,

	draw = function()
		-- draw borders
		Draw.stack(function()
			--love.graphics.scale(BlankE.scale_x, BlankE.scale_y)
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

    	love.graphics.setBlendMode('alpha', 'premultiplied')
		BlankE.drawToScale(function()
			BlankE.game_canvas:draw(true)
			love.graphics.setBlendMode('alpha')
		end)
		if BlankE.draw_debug and Debug then Debug.draw() end

        -- disable any scenes that aren't being actively drawn
        local active_scenes = 0
		_iterateGameGroup('scene', function(scene)
			if scene._is_active > 0 then 
				active_scenes = active_scenes + 1
				scene._is_active = scene._is_active - 1
			end
		end)

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

	keypressed = function(key)
        Input.keypressed(key)
	end,

	keyreleased = function(key)
	    Input.keyreleased(key)
	end,

	mousepressed = function(x, y, button) 
	    x, y = BlankE.scaledMouse(x, y)
	    Input.mousepressed(x, y, button)
	end,

	mousereleased = function(x, y, button) 
	    Input.mousereleased(x, y, button)
	end,

	wheelmoved = function(x, y)
	    Input.wheelmoved(x, y)		
	end,

	_quit = function()
		if BlankE.quit and BlankE.quit() then return true end

	    if Net then Net.disconnect() end
	    --State.switch()
	    --BlankE.clearObjects(true)
		BlankE.restoreCallbacks()
		if Debug then Debug.quit() end

	    -- remove globals
	    local globals = {}--'BlankE'}
	    for g, global in ipairs(globals) do
	    	if _G[global] then _G[global] = nil end
		end
		
		return false
	end,

	errorhandler = function(msg)
		-- local trace = debug.traceback()

		print(debug.traceback("Error: " .. tostring(msg), 10):gsub("\n[^\n]+$", ""))
	 	
	 	-- old_errhand(msg)
	end,
}
--[[
local old_errorhandler = love.errorhandler
love.errorhandler = BlankE.errorhandler]]

BlankE.addClassType('_err_state', 'State')
_err_state.error_msg = 'NO GAME'

local _t = 0
function _err_state:enter(prev)
	love.graphics.setBackgroundColor(0,0,0,0)
end
function _err_state:draw()
	game_width = love.graphics.getWidth()
	game_height = love.graphics.getHeight()
	
	local max_size = math.max(game_width, game_height, 500)

	_t = _t + 1
	if _t >= max_size then _t = 0 end -- don't let _t iterate into infinity


	love.graphics.push('all')

	for i = -max_size, max_size, 10 do
		local radius = max_size - _t + i
		if radius > 20 and radius < max_size then
			local opacity = (radius / max_size) * 0.6
			love.graphics.setColor(0,1,0,opacity)
			love.graphics.circle("line", game_width/2, game_height/2, radius)
		end
	end

	-- draw error message
	local posx = 0
	local posy = game_height/2
	local align = "center"
	if #_err_state.error_msg > 100 then
		align = "left"
		posx = love.window.toPixels(70)
		posy = posx
	end
	love.graphics.setColor(1,1,1,sinusoidal(150,255,0.5)/255)
	love.graphics.printf(_err_state.error_msg,posx,posy,game_width,align)

	love.graphics.pop('all')
end	

--error = BlankE.errorhandler


return BlankE