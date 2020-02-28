Map.config {
    tile_hitbox = { 
		ground='ground',
		spike='death'
	}
}

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
		State.start('play')
    end
}

State("play", {
	enter = function()
        Map.load('level1.map')
	end
})