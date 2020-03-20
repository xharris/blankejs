-- Hitbox.debug = true

-- local map

-- State('ecs',{
-- 	enter = function()
-- 		print("hi")
-- 		Input({
-- 			right = { 'right', 'd' },
-- 			left = { 'left', 'a' },
-- 			up = { 'up', 'w' },
-- 			down = { 'down', 's' },
-- 			action = { 'space' }
-- 		})
		
-- 		Camera("player")--, {zoom=2})
-- 		--Hitbox.debug = true
		
-- 		Map.config{
-- 			tile_hitbox = { megman = 'ground' }	
-- 		}
-- 		map = Map.load('platformer.map')
-- 	end,
-- 	update = function(dt)
-- 		print('going')
-- 		if Input.released('action') then 
-- 			map:destroy()
-- 			map = Map.load('platformer.map')
-- 		end
-- 	end,
-- 	draw = function()
-- 		Draw{
-- 			{'color','white'},
-- 			{'line',-100,0,100,0},
-- 			{'line',0,-100,0,100}
-- 		}
-- 	end
-- })

-- Entity("heart", {
-- 	image = { 'image2.png', align='center' },
-- 	hitbox = true
-- })

-- Entity("player",{
-- 	animation = { 'blue_robot', align='center' },
-- 	camera = { "player" },
-- 	platforming = { gravity=10 },
-- 	hitbox = {
-- 		collision = function(self, v)
-- 			if v.normal.y < 0 then 
-- 				self.vspeed = 0
-- 			end
-- 			if v.normal.y > 0 then 
-- 				self.vspeed = -self.vspeed / 2
-- 			end
-- 		end
-- 	},
-- 	update = function(self, dt)		
-- 		local hspd = 80
-- 		local dx, dy = 0, 0
		
-- 		-- horizontal
-- 		if Input.pressed('right') then 
-- 			dx = dx + hspd 
-- 			self.scalex = 1
-- 		end
-- 		if Input.pressed('left') then 
-- 			dx = dx - hspd 
-- 			self.scalex = -1
-- 		end
-- 		self.hspeed = dx
		
-- 		if Input.released('up') then 
-- 			self.vspeed =  -250 
-- 		end
-- 	end
-- })