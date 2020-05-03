local VIEW_BALL_RANGE = true

local player

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

Audio('bomber_barbara.ogg', {name='main', looping=true, volume=0.05, type='stream'})

Ball = Entity("Ball",{
	hitbox=true,
	reaction="cross",
	animations={ "ball" },
	align="center",
	spawn=function(self)
		-- self.anim_frame = Math.random(1,5)
			
		--				soccer, 	beach, 	spike, 	bowling, 	smile
		local scaling = {0.75,		1,		0.5,		1.5,	0.3 }
		local radius = 	{45,		62,		40,			90,		28 }
		
		self.scale = scaling[self.anim_frame]
		self.radius = radius[self.anim_frame]
	end,
	is_colliding = function(self, other)
		return Math.distance(other.x, other.y, self.x, self.y) <= self.radius
	end,
	draw = function(self, d) 
		d()
		
		if VIEW_BALL_RANGE then
			Draw{
				{ 'color', 'green'},
				{ 'scale', 1/self.scale },
				{ 'print', Math.floor(Math.distance(player.x, player.y, self.x, self.y)) }
			}
		end
	end
})

local hit_effect = {
	red = 0,
	shift_radius = 0,
	static_str = 0
}

Player = Entity("Player",{
	hitbox=true,
	reaction="cross",
	animations={ "bluerobot" },
	align="center",
	z=5,
	collision=function(self, i)
		if i.other.tag == "Ball" and i.other:is_colliding(self) then
			hit_effect.red = 40
			hit_effect.shift_radius = 10
			hit_effect.static_str = 10
			
			if self.hit_effect_tween then 
				self.hit_effect_tween:destroy()
			end
			self.hit_effect_tween = Tween(1, hit_effect, { red=0, shift_radius=0, static_str=0 })
		end
	end,
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
		
		-- mirror player image
		if Input.pressed('left') then 
			self.scalex = -1
		end
		if Input.pressed('right') then 
			self.scalex = 1
		end
		
		Joystick.use()
	end
})

Game{
	background_color = "white",
	plugins = { 'xhh-effect', 'xhh-tween' },
	effect = {  'chroma shift', 'static' },
	load = function()	
		player = Player{x=Game.width/2, y=Game.height/2}
		
		local margin = 50
		for b = 0, 4 do 
			Ball{anim_frame=b+1, x=Math.lerp(margin, Game.width-(margin*2), b/4), y=Game.height/2}
		end
				
		Audio.play('main')
		Audio.volume(0.05)
	end,
	update = function(self, dt)
		Game.effect:set("chroma shift", "radius", hit_effect.shift_radius)
		Game.effect:set("static", "strength", {hit_effect.static_str, 0})
	end,
	draw = function(d)
		d()
		
		Draw{
			{ 'color', 'red', hit_effect.red/100 },
			{ 'rect', 'fill', 0, 0, Game.width, Game.height }
		}
	end
}