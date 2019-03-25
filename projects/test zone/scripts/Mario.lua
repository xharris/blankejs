BlankE.addEntity("Mario");

function Mario:init()
	self:addAnimation{name="mario_walk", image="sprite-example", frames={"1-3",1}, frame_size={29,43}, speed=1, offset={12,8}}
	self.sprite_index = "mario_walk"
	
	self.real_mario = Image("sprite-example")
	self.real_mario.xoffset = self.real_mario.width / 2
	self.real_mario.yoffset = self.real_mario.height / 2
	self.real_mario.x = game_width /2
	self.real_mario.y = game_height /2
	
	self.effect = Effect("chroma shift")
	--self.effect = Effect("static")
	self.direction = 0
end

function Mario:update(dt)	
	local s = 2
	if Input("move_l").pressed then self.direction = self.direction - s end
	if Input("move_r").pressed then self.direction = self.direction + s end
	if Input("move_u").pressed then self:moveDirection(self.direction, 50) end
	if Input("move_d").pressed then self:moveDirection(self.direction, -50) end
	self.sprite_angle = self.direction
	--Debug.log(self.direction, self.hspeed, self.vspeed)
end

function Mario:draw()
	self:drawSprite()
	--[[
	self.effect:draw(function()
		Draw.setColor("black")
		Draw.rect("fill",0,0,game_width/2,game_height)
		Draw.reset("color")
			
		self.real_mario:draw()
	end)]]
end