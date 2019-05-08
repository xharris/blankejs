Window = {
	aspect_ratio = {4,3},
	resolution = 3,
	scale_mode = 'scale', -- scale, stretch, fit, center
	aspect_ratios = { {4,3},{5,4},{16,10},{16,9} },
	resolutions = { 512, 640, 800, 1024, 1280, 1366, 1920 },--640, 800, 960, 1024, 1280, 1400, 1440, 1600, 1856, 1920, 2048 },
	disable_fullscreen = false,
	os='?',
	
	detectAspectRatio = function()
		-- detect aspect ratio
		if Window.os == 'web' then return end
		local w, h = love.window.getDesktopDimensions()
		for r, ratio in ipairs(Window.aspect_ratios) do
			if w * (ratio[2] / ratio[1]) == h then
				Window.aspect_ratio = ratio
			end
		end
	end,

	getResolution = function(index)
		if Window.os == 'web' then return love.window.getMode() end
		if Window._ratio_broken then return unpack(Window.resolution) end

		Window.resolution = ifndef(index, Window.resolution)
		local res = Window.resolutions[Window.resolution]
		return res, res / Window.aspect_ratio[1] * Window.aspect_ratio[2]
	end,

	_ratio_broken = false,
	setResolution = function(w, h)
		if h == nil then
			w, h = Window.getResolution(w)
		else 		
			Window._ratio_broken = true	
			Window.resolution = {w,h}
		end
		if Window.os ~= 'web' then love.window.updateMode(w,h) end
		updateGlobals(0)
		return w, h
	end,

	getFullscreen = function(...)
		if Window.disable_fullscreen == true then return end 
		return love.window.getFullscreen(...)
	end,
	setFullscreen = function(...)
		if Window.disable_fullscreen == true then return end 
		return love.window.setFullscreen(...)
	end,
	toggleFullscreen = function(type)
		Window.setFullscreen(not Window.getFullscreen(),type)
	end,
	
	getPosition = function() return love.window.getPosition() end,
	setPosition = function(x, y, display) love.window.setPosition(x, y, display) end
}

--[[ -- auto detect aspect ratio
local w, h = love.window.getDesktopDimensions()
Window.aspect_ratio[2] = h / (w % h)
Window.aspect_ratio[1] = Window.aspect_ratio[2] * w / h
]]

return Window