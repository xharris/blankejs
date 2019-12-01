import Entity, Game, Canvas, Input, Draw, Audio, Effect, Math, Map, Hitbox from require "blanke"

import p from require "moon"

Game {
    res: 'assets'
    filter: 'nearest'
    load: () ->
        Game.setBackgroundColor(1,1,1,1)
        Map.load('level1.map')
}

Map.config {
    tile_hitbox: { ground:'ground' },
    entities: { 'Player' }
}

Input {
    left: { "left", "a" }
    right: { "right", "d" }
    jump: { "up", "w" }
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
	align: "center",
	scale: 0.5,
	gravity: 5,
	hitboxes: {
		main: 'rect',
		foot: { 'rect', { 0, Image.info('soldier_walk').h, Image.info('soldier_walk').w, 2 } }
	},
	collision: {
		main: (other, vec) =>
			if other.tag == 'ground'
				if Hitbox.test(@x, @y + (@height / 2), 'ground')
					@collisionStopY!
				@collisionStopX!
		foot: (other, vec) =>
			print 'foot'
	},
	draw: (d) =>
		d!
		Draw {
			{ 'color', 0, 0, 1 },
			{ 'print', @width .. ', ' .. @height, @x, @y - 40 },
			{ 'rect', 'fill', @x, @y + (@height / 2), 2, 2 },
			{ 'color' }
		}
    update: (dt) =>
		-- left/right
        dx = 100
		@hspeed = 0
        if Input.pressed('right')
			@hspeed = dx
			@scalex = 1
        if Input.pressed('left')
			@hspeed = -dx
			@scalex = -1
			
		if Input.pressed('right') or Input.pressed('left')
			@animation = 'soldier_walk'
		else
			@animation = 'soldier_stand'
		-- jumping
        if Input.released('jump')
			@vspeed = -200
}