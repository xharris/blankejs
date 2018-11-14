BlankE.addEntity("Penguin")

function Penguin:init()
	self:addAnimation{
		name = 'stand',
		image = 'penguin_outline',
		frames = {1,1},
		frame_size = {32,32}
	}
	self:addAnimation{
		name = 'eyes',
		image = 'penguin_eyes',
		frames = {'1-2', 1},
		frame_size = {32, 32},
		speed = .1
	}
	self:addAnimation{
		name = 'walk',
		image = 'penguin_outline',
		frames = {'1-2', 1},
		frame_size = {32, 32},
		speed = .1
	}
	self:addAnimation{
		name = 'walk_fill',
		image = 'penguin_filler',
		frames = {'1-2', 1},
		frame_size = {32, 32},
		speed = .1
	}

	self.sprite_xoffset = -16
	self.sprite['eyes'].speed = 0
	self.sprite['walk_fill'].color = Draw.blue
end

function Penguin:update(dt)
end

function Penguin:postUpdate(dt)
	if self.hspeed < 0 then self.sprite_xscale = -1 end
	if self.hspeed > 0 then self.sprite_xscale = 1 end
	
	-- walking animation
	local speed = 0
	self.sprite_speed = math.max(math.abs(self.speed), math.abs(self.hspeed), math.abs(self.vspeed)) / 20
	if self.sprite_speed > 0 then self.sprite_speed = math.max(self.sprite_speed, 0.8) end
		
	if self.sprite_speed == 0 then
		self.sprite_speed = 0
		self.sprite_frame = 1
	end
	self.sprite['eyes'].frame = 1
	
	if self.is_special then
		-- Debug.log(self.hspeed, self.vspeed, self.speed)
	end
end

function Penguin:draw()		
	self:drawSprite('walk')
	self:drawSprite('walk_fill')
	--self:drawSprite("eyes")
end