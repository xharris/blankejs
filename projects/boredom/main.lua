Game { 
    res = 'assets',
    filter = 'nearest',
	plugins = { 'xhh-effect', 'xhh-tween' },
    load = function()
        Game.setBackgroundColor('white')
        Map.load('level1.map')	
    end
}

Map.config {
    tile_hitbox = { 
		ground='ground',
		spike='death'
	},
    entities = { 'Player' }
}

Input({
    left = { "left", "a" },
    right = { "right", "d" },
    jump = { "up", "w" },
    action = { 'space' }
}, { no_repeat = { "jump" } })