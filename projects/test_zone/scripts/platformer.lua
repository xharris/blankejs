-- Hitbox.debug = true
local bg 
local map
State('platformer',{
	enter = function()
		Input.set({
			right = { 'right', 'd', 'gp.dpright' },
			left = { 'left', 'a', 'gp.dpleft' },
			up = { 'up', 'w', 'gp.a' },
			down = { 'down', 's' },
			action = { 'space' }
		})
		--Game.setEffect('static')
		bg = Background{file="megman.png"}
		
		Camera("player")--, {zoom=2})
		--Hitbox.debug = true
		
		Map.config{
			tile_hitbox = { megman = 'ground' }	
		}
		map = Map.load('platformer.map')
	end,
	update = function(dt)
		if Input.released('action') then 
			map:destroy()
			map = Map.load('platformer.map')
		end
		local cam = Camera.get("player")
		bg.size = 'cover'
		bg.x = -cam.x/2
		bg.y = -cam.y/2
	end,
	draw = function()
		Draw{
			{'color','white'},
			{'line',-100,0,100,0},
			{'line',0,-100,0,100}
		}
	--[[
		Draw.color('green')
		local cam = Camera.get("player")
		
		local game_diag = Math.sqrt((Game.width^2) + (Game.height^2))
		for r = 20, game_diag, 20 do
			local cr = r - (Game.time * 50 % 20)
			print(cr, game_diag)
			Draw.lineWidth(Math.lerp(0,50,cr/game_diag))
			Draw.circle('line',cam.x,cam.y,cr)
		end
	]]
	end
})

Entity("heart", {
	images = { 'image2.png' },
	align = 'center',
	hitbox = true,
})

Entity("player",{
	animations = { 'blue_robot' },
	align = 'center',
	camera = "player",
	hitbox = true,
	gravity = 10,
	--debug = true,
	collision = function(self, v)
		if v.normal.y < 0 then 
			self.vspeed = 0
		end
		if v.normal.y > 0 then 
			self.vspeed = -self.vspeed / 2
		end
	end,
	update = function(self, dt)		
		local hspd = 80
		local dx, dy = 0, 0
		
		local leftx = Input("gp.leftx")
		
		-- horizontal
		if Input.pressed('right') then 
			dx = dx + hspd 
			self.scalex = 1
		end
		if Input.pressed('left') then 
			dx = dx - hspd 
			self.scalex = -1
		end
		if leftx then 
			local val = Math.abs(leftx.value) < 0.1 and 0 or leftx.value
			dx = dx + (hspd * val) 
			leftx.joystick:setVibration(Math.abs(val), Math.abs(val))
		end
		
		self.hspeed = dx
		
		if Input.released('up') then 
			self.vspeed =  -250 
			print("ok", self.vspeed)
		end
	end
})