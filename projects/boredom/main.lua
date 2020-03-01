Map.config {
    tile_hitbox = { 
		ground='ground',
		spike='death'
	}
}

local map

Input({
    left = { "left", "a" },
    right = { "right", "d" },
    jump = { "up", "w" },
	action = { 'space' },	
})

Game { 
    res = 'assets',
    filter = 'nearest',
	plugins = { 'xhh-effect', 'xhh-tween' },
	background_color = "white",
    load = function()
		Tween(1, { hspeed=5}, { hspeed=0 }, nil, function() print('wow') end)
		State.start('play')
	end
}

State("play", {
	enter = function()
        map = Map.load('level1.map')
	end
})