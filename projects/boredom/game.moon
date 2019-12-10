import Game, Input, Map from require "blanke"

import p from require "moon"

Game {
    res: 'assets'
    filter: 'nearest'
	scripts: { 'xhh-effect', 'player' }
	--effect: 'chroma shift'
    load: () ->
        Game.setBackgroundColor('white')
        Map.load('level1.map')	
}

Map.config {
    tile_hitbox: { 
		ground:'ground',
		spike:'death'
	},
    entities: { 'Player' }
}

Input {
    left: { "left", "a" }
    right: { "right", "d" }
    jump: { "up", "w" }
    action: { 'space', 'mouse1' }
}, { no_repeat: { "jump" } }