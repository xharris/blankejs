import Entity, Game, Canvas, Input, Draw, Audio, Effect, Math, Map from require "blanke"

import is_object, p from require "moon"

Game {
    res: 'assets'
    filter: 'nearest'
    load: () ->
        Game.setBackgroundColor(1,1,1,1)
        Map.load('level1.map')
		
}

Map.config {
    tile_hitbox: { 'ground' },
    entities: { 'Player' }
}

Input {
    left: { "left", "a" }
    right: { "right", "d" }
    up: { "up", "w" }
    action: { 'space', 'mouse1' }
}, { no_repeat: { "up" } }

Camera "player"

Image.animation 'soldier_full.png', {
	{ name: 'soldier_walk', frames:{ '1-6' }, rows:2, cols:3 },
	{ name: 'soldier_stand', frames:{ 3 } }
}, { rows:2, cols:3, duration:0.1 }

Entity "Player", {
	camera: 'player',
	animations: {'soldier_stand','soldier_walk'},
    scalex: 2,
    testdraw: {
        { color: {1, 0, 0, 0.5} },
        { line: {0, 0, Game.width/2, Game.height/2} }
    }
    update: (dt) =>
        hspeed = 100
        if Input.pressed('right')
            @x += hspeed * dt
        if Input.pressed('left')
            @x -= hspeed * dt
			
		if Input.pressed('right') or Input.pressed('left')
			@animation = 'soldier_walk'
		else
			@animation = 'soldier_stand'
			
        if Input.released('action')
            Audio.play('fire.ogg')
}