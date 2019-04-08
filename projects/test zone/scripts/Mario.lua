BlankE.addEntity("Mario");

function Mario:init()
	self:addAnimation{name="mario_walk", image="sprite-example", frames={"1-3",1}, frame_size={29,43}, speed=1, offset={12,8}}
	self.sprite_index = "mario_walk"
	self.sprite_xoffset = -self.sprite_width/2
	self.sprite_yoffset = -self.sprite_height/2
	
	self.real_mario = Image("sprite-example")
	self.real_mario.xoffset = self.real_mario.width / 2
	self.real_mario.yoffset = self.real_mario.height / 2
	self.real_mario.x = game_width /2
	self.real_mario.y = game_height /2
	
	self.effect = Effect("chroma shift")
	--self.effect = Effect("static")
	self.direction = 0
	self.can_jump = true
	
	self:addPlatforming()
	self.gravity_direction = 90
	self.gravity = 10
	
	Input("move_u").can_repeat = false
end

function Mario:update(dt)	
	local s = 200
	local hx = 0
	if Input("move_l").pressed then hx = hx - s end
	if Input("move_r").pressed then hx = hx + s end
	
	if Input("move_u").released then self.can_jump = true end
	if Input("move_u").pressed and self.can_jump then 
		self.vspeed = -500
		self.can_jump = false
	end
	self.hspeed = hx
	
	self:platformerCollide{tag="ground"}
end

function Mario:draw()
	self:drawSprite()
	self:debugCollision()
	--[[
	self.effect:draw(function()
		Draw.setColor("black")
		Draw.rect("fill",0,0,game_width/2,game_height)
		Draw.reset("color")
			
		self.real_mario:draw()
	end)]]
end