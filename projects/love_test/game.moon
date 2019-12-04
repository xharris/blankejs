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
	gravity: 10,
	hitbox: true,
	margin: 2,
	can_jump: true,
	collFilter: (other) =>
		return 'slide'
	collision: (v) =>
		if v.normal.y ~= 0
			@can_jump = true
			@vspeed = 0
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
        if Input.pressed('jump') and @can_jump
			@vspeed = -300
			@can_jump = false
}