BlankE.addEntity("Penguin");

local my_eff
function Penguin:init()
	self:addAnimation{name="stand", image="Basic Bird", frames={1,1,1,1}, frame_size={23,22}, speed=1, offset={0,0}}

	self.sprite_xoffset = -self.sprite_width / 2
	self.sprite_yoffset = -self.sprite_height / 2
	
	self:addPlatforming(0,0,self.sprite_width,self.sprite_height)
	self.gravity = 20
end

function Penguin:update(dt)	
	self.hspeed = 0
	self:platformerCollide{tag="ground"}
	  
	if Input("move_l").pressed then
		self.hspeed = -300
	end
	if Input("move_r").pressed then
		self.hspeed = 300
	end
	
	if Input("move_u").pressed then
		self.vspeed = -500
	end 
end

function Penguin:draw()
	
end