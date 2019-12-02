import Entity, Game, Canvas, Input, Draw, Audio, Effect, Math, Map, Physics from require "blanke"

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
}, { no_repeat: { "jump" } }

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
	gravity: 20,
	hitbox: true,
	margin: 3,
	collision: (other) =>
		if other.y > @y
			@vspeed = 0
		return 'slide'
	draw: (d) =>
		d!
		Draw {
			{ 'color', 0, 0, 1 },
			{ 'print', @hspeed .. ', ' .. @vspeed, @x, @y - 40 },
			{ 'rect', 'fill', @x, @y + (@height / 2), 2, 2 },
			{ 'color' }
		}
    update: (dt) =>
		-- left/right
        dx = 150
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
        if Input.pressed('jump')
			@vspeed = -300
}