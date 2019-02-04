BlankE.addEntity("Asteroid")
BlankE.addEntity("Bullet")

function Asteroid:init(size)
	self:addAnimation{name="asteroid", image="asteroids", frames={"1-3",1}, frame_size={68,68}, speed=1, offset={0,0}}
	
	self.sprite_speed = 0
	self.sprite_frame = randRange(1,3)
	self.sprite_xoffset = -self.sprite_width / 2
	self.sprite_yoffset = -self.sprite_height/ 2
	
	bob = Effect("chroma_shift","static")
	
	size = ifndef(size, 1)

	self.size = size
	self.sprite_xscale = 1 / size
	self.sprite_yscale = 1 / size
		
	-- random starting speed
	self.speed = randRange(-60,-80,60,80)
	self.direction = randRange(0,360)
	
	-- start outside of screen
	self.x, self.y = unpack(table.random{
		{-self.sprite_width, randRange(0, game_height)},
		{game_width + self.sprite_width, randRange(0, game_height)},
		{randRange(0, game_width), -self.sprite_height},
		{randRange(0, game_width), game_height + self.sprite_height}			
	})	
	
	self:addShape("main","circle",{0,0,32})
	self.children = Group()
	self.show_debug = true
end

function Asteroid:checkDie()
	if self.children:size() == 1 then
		self:destroy()
	end
end

function Asteroid:hit()
	if self.size < 2 and self.sprite_alpha > 0 then
		local a1 = Asteroid(self.size + 1)
		local a2 = Asteroid(self.size + 1)
		a1.x, a1.y = self.x, self.y 
		a2.x, a2.y = self.x, self.y
	
		a1.direction = self.direction - 90
		a1.parent = self
		a2.direction = self.direction + 90
		a2.parent = self
		
		self.children:add(a1, a2)
		
		self:removeShape("main")
		self.sprite_alpha = 0
	elseif self.parent then
		self.parent:checkDie()
		self:destroy()	
	end
end

function Asteroid:update(dt)
	if self.x > game_width then self.x = 0 end
	if self.y > game_height then self.y = 0 end
	if self.x < 0 then self.x = game_width end
	if self.y < 0 then self.y = game_height end

	self.onCollision["main"] = function(other, sep_vec)
		if other.parent.classname == "Bullet" then
			other.parent:destroy()
			self:hit()
		end
	end
end

function Asteroid:draw()
	self:drawSprite()
	self.children:call('draw')
	self:debugCollision()
end