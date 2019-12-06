import Entity, Input from require "blanke"
import Tween from require "xhh-tween"

Camera "player"

Image.animation 'player_stand.png'
Image.animation 'player_dead.png'
Image.animation 'player_walk.png', { { rows:1, cols:2, duration: 0.2 } }

Hitbox.debug = true

Entity "Player", {
	camera: 'player',
	animations: {'player_stand','player_walk','player_dead'},
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
		if v.other.tag == 'death'
			@die!
		if v.normal.y < 0
			@can_jump = true
			@vspeed = 0
		if v.normal.y > 0
			@vspeed = -@vspeed
	die: () =>
		if not @dead
			@dead = true
			Tween 2, @, { hspeed:0 }
    update: (dt) =>
		if @dead	
			@animation = "player_dead"
			-- @hitArea = {}
		else 
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
				@animation = 'player_walk'
			else
				@animation = 'player_stand'
			-- jumping
			if Input.pressed('jump') and @can_jump
				@vspeed = -300
				@can_jump = false


			@animList['player_walk'].speed = 1
			if @vspeed ~= 0 or not @can_jump
				@animation = 'player_walk'
				@animList['player_walk'].speed = 0
				@animList['player_walk'].frame_index = 2
}