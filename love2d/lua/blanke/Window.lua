Window = {
	aspect_ratio = {4,3},
	resolution = 1,
	scale_mode = 'scale',

	aspect_ratios = { {4,3},{16,10},{16,9} },
	resolutions = { 640, 800, 960, 1024, 1280, 1400, 1440, 1600, 1856, 1920, 2048 },
	
	getResolution = function(index)
		Window.resolution = ifndef(index, Window.resolution)
		local res = Window.resolutions[Window.resolution]
		return res, res / Window.aspect_ratio[1] * Window.aspect_ratio[2]
	end,

	setResolution = function(w, h)
		if not h then
			w, h = Window.getResolution(w)
		end
		love.window.updateMode(w,h)
	end
}

--[[ -- auto detect aspect ratio
local w, h = love.window.getDesktopDimensions()
Window.aspect_ratio[2] = h / (w % h)
Window.aspect_ratio[1] = Window.aspect_ratio[2] * w / h
]]

return Window