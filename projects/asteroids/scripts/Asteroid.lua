BlankE.addEntity("Asteroid")
BlankE.addEntity("Bullet")

function Asteroid:init(small)
	if not small then
		self:addAnimation{name="asteroid", image="asteroids", frames={"1-3",1}, frame_size={68,68}, speed=1, offset={0,0}}
		self:addShape("main","circle",{0,0,32})
	else
		self:addAnimation{name="asteroid", image="asteroids_small", frames={"1-3",1}, frame_size={34,34}, speed=1, offset={0,0}}
		self:addShape("main","circle",{0,0,16})
	end
		
	self.sprite_speed = 0
	self.sprite_frame = randRange(1,3)
	self.sprite_xoffset = -self.sprite_width / 2
	self.sprite_yoffset = -self.sprite_height/ 2
		
	self.small = small
		
	-- random starting speed
	self.speed = randRange(-70,-80,70,80)
	self.direction = randRange(0,360)
	
	-- start outside of screen
	self.x, self.y = unpack(table.random{
		{-self.sprite_width, randRange(0, game_height)},
		{game_width + self.sprite_width, randRange(0, game_height)},
		{randRange(0, game_width), -self.sprite_height},
		{randRange(0, game_width), game_height + self.sprite_height}			
	})	
	
	self.children = Group()
	self.show_debug = true
end

function Asteroid:checkDie()
	if self.children:size() == 1 then
		self:destroy()
	end
end

function Asteroid:hit(bullet)
	if not self.small and self.sprite_alpha > 0 then
		local split_count = randRange(2,4)
		if split_count == 4 then split_count = 8 end
				
		local last_dir = 0
		-- calculate direction based on collision direction (does this even work lol)
		if bullet then 
			last_dir = bullet.direction - ((split_count/2) * 45)
		end
		for a = 1, split_count do
			local new_a = Asteroid(true)
			new_a.x, new_a.y = self.x, self.y
			new_a.speed = self.speed * (randRange(175, 225)/100)
			last_dir = last_dir + randRange(10,45)
			new_a.direction = last_dir
			new_a.parent = self
			
			self.children:add(new_a)
		end
		
		self:removeShape("main")
		self.sprite_alpha = 0
	elseif self.parent then
		self.parent:checkDie()
		self:destroy()	
	end
	
	if bullet then bullet:destroy() end
end

function Asteroid:update(dt)
	local sw = self.sprite_width
	local sh = self.sprite_height
	
	if self.x > game_width + sw then self.x = -sw end
	if self.y > game_height + sh then self.y = -sh end
	if self.x < -sw then self.x = game_width + sw end
	if self.y < -sh then self.y = game_height + sh end

	self.onCollision["main"] = function(other, sep_vec)
		if other.parent.classname == "Bullet" then
			self:hit(other.parent)
		end
	end
end

function Asteroid:draw()
	self:drawSprite()
	self.children:call('draw')
	self:debugCollision()
end