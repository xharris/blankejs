import Entity, Game, Canvas, Input, Draw, Audio, Effect, Math, Map, Physics, Hitbox from require "blanke"

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

Image.animation 'player_stand.png'
Image.animation 'player_walk.png', { { rows:1, cols:2, duration: 0.2 } }

Hitbox.debug = true

Entity "Player", {
	camera: 'player',
	animations: {'player_stand','player_walk'},
	align: "center",
	gravity: 10,
	can_jump: true,
	hitbox: true,
	hitArea: {
		left: -5
		right: -10
	},
	collFilter: (other) =>
		return 'slide'
	collision: (v) =>
		if v.normal.y ~= 0
			@can_jump = true
			@vspeed = 0
    update: (dt) =>
		-- left/right\
        dx = 150
		@hspeed = 0
        if Input.pressed('right')
			@hspeed = dx
			@scalex = 1
        if Input.pressed('left')
			@hspeed = -dx
			@scalex = -1
			
		if Input.pressed('right') or Input.pressed('left')
			@animation = 'player_walk'
		else
			@animation = 'player_stand'
		-- jumping
        if Input.pressed('jump') and @can_jump
			@vspeed = -300
			@can_jump = false
}