import p from require "moon"
p blanke
print blanke
print 'hi'
import Game, Input, Map from require blanke
print 2


print 3
Game { 
    res: 'assets'
    filter: 'nearest'
	scripts: { 'xhh-effect' }
    load: () ->
		print love.graphics.getDefaultFilter!
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
    action: { 'space' }
}, { no_repeat: { "jump" } }