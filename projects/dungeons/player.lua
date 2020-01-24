Input({    
	left = { "left", "a" },
    right = { "right", "d" },
	up = { "up", "w" },
	down = { "down", "s" }
})

Hitbox.debug = true

Entity("player",{
	hitbox = true,
	hitArea = { left=-10, top=-10, right=20, bottom=20},
	collList = { wall = 'slide' },
	update = function(self, dt)
		self.hspeed = 0
		self.vspeed = 0
		local dx, dy, s = 0, 0, 400
			
		if Input.pressed("left") 	then dx = -s end
		if Input.pressed("right")	then dx = s end
		if Input.pressed("up")		then dy = -s end
		if Input.pressed("down")	then dy = s end
		
		self.hspeed = dx
		self.vspeed = dy
	end,
	draw = function(self)
		Draw{
			{'color','white2'},
			{'rect','fill',self.x-10,self.y-10,20,20}
		}
	end
})