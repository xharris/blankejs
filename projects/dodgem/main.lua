Image.animation("balls.png",{
	{ name="ball", rows=1, cols=5, speed=0 }
})
Image.animation("bluerobot.png",{
	{ name="bluerobot", rows=1, cols=8, frames={'2-7'}, speed=15 }
})

Input.set({
    left = { "left", "a", "dpleft" },
    right = { "right", "d", "dpright" },
	up = { "up", "w", "dpup" },
	down = { "down", "s", "dpdown" }
})

Audio('bomber_barbara.ogg', {name='main', looping=true, volume=0.2, type='stream'})

Ball = Entity("Ball",{
	hitbox=true,
	animations={ "ball" },
	align="center"
})

Player = Entity("Player",{
	hitbox=true,
	animations={ "bluerobot" },
	align="center",
	update = function(self, dt)
		local d = 100
		self.hspeed = 0
		self.vspeed = 0
		-- basic movement
		Joystick.use(1)
		if Input.pressed('left') then self.hspeed = self.hspeed - d end
		if Input.pressed('right') then self.hspeed = self.hspeed + d end
		if Input.pressed('up') then self.vspeed = self.vspeed - d end
		if Input.pressed('down') then self.vspeed = self.vspeed + d end
		Joystick.use()
	end
})

Game{
	background_color = "white",
	load = function()
		local ball1 = Ball{x=Game.width/2, y=Game.height/2, anim_frame=3}
		Player({x=ball1.x + 20, y=Game.height/2})
		Audio.play('main')
	end
}

Hitbox.debug = true