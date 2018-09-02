mouse_x = 0
mouse_y = 0
game_width = 0
game_height = 0
window_width = 0
window_height = 0
game_time = 0
dt_mod = 1

CONF = {
    window = {
        width = 800,
        height = 600
    }
}

function updateGlobals(dt)
	game_time = game_time + dt

	local width, height = love.window.fromPixels(love.graphics.getDimensions())
	local x_scale, y_scale = width / CONF.window.width, height / CONF.window.height
	local new_width, new_height = width, height

	if not BlankE then return end

	if Window.scale_mode == 'stretch' then
		BlankE.scale_x = x_scale
		BlankE.scale_y = y_scale
		BlankE.left = 0
		BlankE.top = 0
		new_width, new_height = width / x_scale, height / y_scale
	end

	-- TODO: doesn't work if window is greater than desired width/height
	if Window.scale_mode == 'scale' then
		local scale = (math.min(x_scale, y_scale))
		new_width, new_height = width / x_scale, height / y_scale

		BlankE.scale_x = scale
		BlankE.scale_y = scale
		BlankE._offset_x = 0
		BlankE._offset_y = 0
		if x_scale > y_scale then
			BlankE._offset_x = math.abs((width / scale / 2) - (new_width / 2))
		else
			BlankE._offset_y = math.abs((height / scale / 2) - (new_height / 2))
		end
	end

	-- not working yet
	if Window.scale_mode == 'fit' then
		local scale = (math.max(x_scale, y_scale))
		new_width, new_height = width / x_scale, height / y_scale

		BlankE.scale_x = scale
		BlankE.scale_y = scale
		BlankE._offset_x = 0
		BlankE._offset_y = 0
		if x_scale < y_scale then
			BlankE._offset_x = -math.abs((width / scale / 2) - (new_width / 2))
		else
			BlankE._offset_y = -math.abs((height / scale / 2) - (new_height / 2))
		end
	end

	if Window.scale_mode == 'center' then
		BlankE.scale_x = 1
		BlankE.scale_y = 1
	end

	mouse_x, mouse_y = BlankE.scaledMouse(love.mouse.getX() + ifndef(Effect._mouse_offx, 0), love.mouse.getY() + ifndef(Effect._mouse_offy, 0))
	game_width = new_width
	game_height = new_height
	window_width = width / BlankE.scale_x
	window_height = height / BlankE.scale_y

	BlankE.right = game_width
	BlankE.bottom = game_height
	BlankE.left = math.abs(BlankE._offset_x) * BlankE.scale_x
	BlankE.top = math.abs(BlankE._offset_y) * BlankE.scale_y

	if BlankE.right > window_width then BlankE.right = window_width	end
	if BlankE.bottom > window_height then BlankE.bottom = window_height end
end

updateGlobals(0)