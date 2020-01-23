local gmap, player

Camera("main",{
	angle = 45		
})

Game{
	filter = "nearest",
	load = function()
		gmap = GMap()
		player = Game.spawn('player')
	end,
	draw = function(d)
		local x, y = gmap:getFocusPos(player.x, player.y)
		local cam = Camera.get("main")
		cam.x = x
		cam.y = y
		Camera.use('main', function()
			gmap:draw()
			d()
		end)
	end
}