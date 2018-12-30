Window = {
	aspect_ratio = {4,3},
	resolution = 1,
	scale_mode = 'scale',

	aspect_ratios = { {4,3},{5,4},{16,10},{16,9} },
	resolutions = { 512, 640, 800, 1024, 1280, 1366, 1920 },--640, 800, 960, 1024, 1280, 1400, 1440, 1600, 1856, 1920, 2048 },
	
	getResolution = function(index)
		Window.resolution = ifndef(index, Window.resolution)
		local res = Window.resolutions[Window.resolution]
		return res, res / Window.aspect_ratio[1] * Window.aspect_ratio[2]
	end,

	setResolution = function(w, h, resize_canvas)
		if not h then
			w, h = Window.getResolution(w)
		end
		if resize_canvas then BlankE.game_canvas:resize(w,h) end
		love.window.updateMode(w,h)
		updateGlobals(0)
	end,

	getFullscreen = love.window.getFullscreen,
	setFullscreen = love.window.setFullscreen,
	toggleFullscreen = function()
		Window.setFullscreen(not Window.getFullscreen())
	end,
}

--[[ -- auto detect aspect ratio
local w, h = love.window.getDesktopDimensions()
Window.aspect_ratio[2] = h / (w % h)
Window.aspect_ratio[1] = Window.aspect_ratio[2] * w / h
]]

return Window