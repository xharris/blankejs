local Graph = blanke_require('plugins.Pathfinder.Graph')

Pathfinder = Class{
	obstacles = {}, -- contains {'obstacle_name'={'x.y'=true/false,...},...}
	init = function(self, w, h, cell_size)
		self.obj = nil

		self.cell_size = cell_size or 5
		self.width = w or game_width
		self.height = h or game_height
		self.obstacles = {}

		_addGameObject('pathing',self)
	end,

	Graph = function() return Graph() end,

	addObstacle = function(self, obj)

	end,

	getPath = function(self, start_x, start_y, end_x, end_y)

	end,

	draw = function(self)
	-- bob
	end
}

return Pathfinder