BlankE.addEntity("Asteroid")
BlankE.addEntity("Bullet")

function Asteroid:init()
	self:addAnimation{name="asteroid", image="asteroids", frames={"1-3",1}, frame_size={68,68}, speed=1, offset={0,0}}
	
	self.sprite_speed = 0
	self.sprite_frame = randRange(1,3)
	self.sprite_xoffset = -self.sprite_width / 2
	self.sprite_yoffset = -self.sprite_height/ 2
	
	self.size = 1
	
	-- start outside of screen
	self.entering = true
	self.x = -self.sprite_width
	self.y = randRange(0, game_height)
	
	-- random starting speed
	if self.x < 0
	self.move_speed = randRange(-50,-70,50,70)
	self.hspeed = randRange(-self.move_speed,self.move_speed)
	self.vspeed = randRange(-self.move_speed,self.move_speed)
end