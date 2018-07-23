Window = {
	aspect_ratio = {0,0},
	resolutions = {

	},
	setResolution = function(w, h)
		if not h then
			-- use a preset resolution

		end
		Debug.log(w,h,)
	end
}

local w, h = love.window.getDesktopDimensions()
Window.aspect_ratio = math.floor(w/h)

return Window