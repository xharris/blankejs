Image.animation("balls.png",{
	{ name="ball", rows=1, cols=5, speed=0 }
})
Image.animation("bluerobot.png",{
	{ name="bluerobot", rows=1, cols=8 }
})

Input({
    left = { "left", "a" },
    right = { "right", "d" },
	up = { "up", "w" },
	down = { "down", "s" }
})

Ball = Entity("Ball",{
	hitbox={
		type='circle',
		radius=50
	},
	animations={ "ball" },
	align="center"
})

Player = Entity("Player",{
	hitbox=true,
	animations={ "bluerobot" },
	align="center",
	update = function(self, dt)
		local d = 50
		self.hspeed = 0
		self.vspeed = 0
		if Input.pressed('left') then self.hspeed = self.hspeed - d end
		if Input.pressed('right') then self.hspeed = self.hspeed + d end
		if Input.pressed('up') then self.vspeed = self.vspeed - d end
		if Input.pressed('down') then self.vspeed = self.vspeed + d end
	end
})

Game{
	load = function()
		local ball1 = Ball({x=Game.width/2, y=Game.height/2, anim_frame=3})
		Player({x=ball1.x + 20, y=Game.height/2})
	end
}

Hitbox.debug = true