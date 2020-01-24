local gmap, player, last_cam_pos, twn

Camera("main")

Game{
	plugins = { "xhh-tween" },
	filter = "nearest",
	load = function()
		gmap = GMap()
		player = Game.spawn('player', {x=GRoom.size[1] / 2, y=GRoom.size[2] / 2})
	end,
	draw = function(d)
		local x, y = gmap:getFocusPos(player.x, player.y)
		local cam = Camera.get("main")
		if not last_cam_pos then 
			last_cam_pos = {x,y}
			cam.x, cam.y = x, y
		elseif last_cam_pos[1] ~= x or last_cam_pos[2] ~= y then
			if twn then twn:destroy() end
			twn = Tween(0.2, cam, {x=x,y=y}, 'outQuart')
			last_cam_pos = {x,y}
		end
		Camera.use('main', function()
			Draw.stack(function()
				Draw.crop((Game.width - GRoom.size[1])/2, (Game.height - GRoom.size[2])/2, GRoom.size[1], GRoom.size[2])
				gmap:draw()
			end)
			d()
		end)
	end
}