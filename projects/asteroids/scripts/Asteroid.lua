BlankE.addEntity("Asteroid")
BlankE.addEntity("Bullet")

function Asteroid:init()
	self:addAnimation{name="asteroid", image="asteroids", frames={"1-3",1}, frame_size={68,68}, speed=1, offset={0,0}}
	
	self.sprite_speed = 0
	self.sprite_frame = randRange(1,3)
	self.sprite_xoffset = -self.sprite_width / 2
	self.sprite_yoffset = -self.sprite_height/ 2
	
	self.size = 1
	
	-- random starting speed
	self.move_speed = randRange(-60,-80,60,80)
	self.hspeed = randRange(-self.move_speed,self.move_speed)
	self.vspeed = randRange(-self.move_speed,self.move_speed)
	
	-- start outside of screen
	self.x, self.y = unpack(table.random{
		{-self.sprite_width, randRange(0, game_height)},
		{game_width + self.sprite_width, randRange(0, game_height)},
		{randRange(0, game_width), -self.sprite_height},
		{randRange(0, game_width), game_height + self.sprite_height}			
	})
end

function Asteroid:update(dt)
	if self.x + self.sprite_width > game_width then self.x = -self.sprite_width end
	if self.y + self.sprite_height > game_height then self.y = -self.sprite_height end
	if self.x < -self.sprite_width then self.x = game_width + self.sprite_width end
	if self.y < -self.sprite_height then self.y = game_height + self.sprite_height end
end