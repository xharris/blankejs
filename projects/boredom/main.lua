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
    action = { 'space' }
}, { no_repeat = { "jump" } })

Game { 
    res = 'assets',
    filter = 'nearest',
	plugins = { 'xhh-effect', 'xhh-tween' },
	backgroundColor = "white",
    load = function()
		Net.on('ready', function()
			State.start('play')
		end)
		Net.connect()
    end
}

State("play", {
	enter = function()
        Map.load('level1.map')
	end
})