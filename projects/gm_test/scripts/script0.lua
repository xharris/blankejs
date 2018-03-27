BlankE.addClassType("mainState", "State")

function mainState:draw()
	Draw.setColor("white")
	
	for i = 0, 360, 30 do
		local d = i + game_time * 30
		local dx = direction_x(d, 64)
		local dy = direction_y(d, 32)
		local r = 10 + dy / 10
		10.01
		-- Draw.circle("fill", 96+dx + (game_width/2) - (r/2), 64+dy + (game_height/2) - (r/2), r)
		Draw.setAlpha((/360)*255)
		Draw.circle("fill", 96+dx + (game_width/2) - (r/2), 64+dy + (game_height/2) - (r/2), r)
	end
end