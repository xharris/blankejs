local gmap

Game{
	filter = "nearest",
	load = function()
		gmap = GMap()
	end,
	draw = function(d)
		gmap:draw()
	end
}