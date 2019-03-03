BlankE.addEntity("Asteroid")
BlankE.addEntity("Bullet")

Asteroid.net_sync_vars = {'x','y','speed','direction','small','split_count','sprite_frame'}

function Asteroid:init(small)	
	self.keep_on_disconnect = true
	
	self:addAnimation{name="small", image="asteroids_small", frames={"1-3",1}, frame_size={34,34}, speed=1, offset={0,0}}
	self:addAnimation{name="large", image="asteroids", frames={"1-3",1}, frame_size={68,68}, speed=1, offset={0,0}}

	self.small = ifndef(small, false)
	if self.small then
		self.snd_hit = Audio("bangSmall")
		self:addShape("main","circle",{0,0,16})
	else
		self.snd_hit = Audio("bangMedium")
		self:addShape("main","circle",{0,0,32})
	end
	-- self.snd_hit.positional = true
			
	self.sprite_speed = 0
	self.sprite_frame = randRange(1,3)
		
	self.split_count = randRange(2,4)
	if self.split_count == 4 then self.split_count = 8 end
		
	-- random starting speed
	self.speed = randRange(-70,-80,70,80)
	self.direction = randRange(0,360)
		
	self.wrap_w = -self.sprite_width/2
	self.wrap_h = -self.sprite_height/2
	
	-- start outside of screen
	local x, y = unpack{randRange(-self.wrap_w,game_width+self.wrap_w), randRange(-self.wrap_h,game_height+self.wrap_h)}
	local bad_spot = false
	repeat
		bad_spot = false
		Ship.instances:forEach(function(s, ship)
			if ship:distancePoint(x,y) < 90 then
				bad_spot = true
				x, y = unpack{randRange(-self.wrap_w,game_width+self.wrap_w), randRange(-self.wrap_h,game_height+self.wrap_h)}
			end
		end)
	until not bad_spot
		
	self.x, self.y = x, y
	
	self.points = 100
	self.children = Group()
	
	Net.once(function() Net.addObject(self) end)
end

function Asteroid:checkDie()
	if self.children:size() == 1 then
		self:destroy()
	end
end

function Asteroid:hit(direction)
	self:netSync("hit",direction)
	
	self.snd_hit.x = lerp(-1,1,self.x/game_width)
	self.snd_hit:play()
	
	Signal.emit("explosion", self.x, self.y, self.small)
	
	if not self.small and self.children:size() == 0 then
		Net.once(function()				
			local last_dir = 0
			-- calculate direction based on collision direction (does this even work lol)
			if direction then 
				last_dir = direction - ((self.split_count/2) * 45)
			end
			for a = 1, self.split_count do
				local new_a = Asteroid(true)
				new_a.x, new_a.y = self.x, self.y
				new_a.points = 50
				if self.split_count >= 4 then new_a.points = 20 end
					
				new_a:netSync('x','y','points')
				new_a.speed = self.speed * (randRange(175, 225)/100)
				last_dir = last_dir + randRange(10,45)
				new_a.direction = last_dir
				new_a.parent = self

				self.children:add(new_a)
			end
		end)
		
		self:removeShape("main")
		self.x = 0
		self.y = 0
		self.speed = 0
	elseif self.parent then
		self.parent:checkDie()
		self:destroy()	
	end
	
	if bullet then bullet:destroy() end
end

function Asteroid:update(dt)
	self.wrap_w = -self.sprite_width/2
	self.wrap_h = -self.sprite_height/2
	
	local sw = self.wrap_w
	local sh = self.wrap_h
	
	if self.x > game_width + sw then self.x = -sw end
	if self.y > game_height + sh then self.y = -sh end
	if self.x < -sw then self.x = game_width + sw end
	if self.y < -sh then self.y = game_height + sh end
	
	
	self.sprite_xoffset = -self.sprite_width / 2
	self.sprite_yoffset = -self.sprite_height/ 2
end

function Asteroid:draw()
	-- SMALL/LARGE ASTEROID
	if self.small then
		self.sprite_index = "small"
	else
		self.sprite_index = "large"
	end
	
	if self.speed == 0 then
		self.children:call('draw') 
	else
		self:drawSprite()
	end
end