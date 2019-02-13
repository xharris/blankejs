BlankE.addEntity("Mario");

function Mario:init()
	self:addAnimation{name="mario_walk", image="sprite-example", frames={"1-3",1}, frame_size={31,44}, speed=0.2, offset={41,8}}
	self.sprite_index = "mario_walk"
	
	self.real_mario = Image("sprite-example")
	self.real_mario.xoffset = self.real_mario.width / 2
	self.real_mario.yoffset = self.real_mario.height / 2
	self.real_mario.x = game_width /2
	self.real_mario.y = game_height /2
	self.real_mario.angle = 45
	
	self.pieces = self.real_mario:chop(4,4)
end

function Mario:update(dt)
	self.pieces:forEach(function(p,piece)
		piece.angle = 90 * (mouse_x / game_width)
	end)
	
	local s = 2
	if Input("move_l").pressed then self.x = self.x - s end
	if Input("move_r").pressed then self.x = self.x + s end
	if Input("move_u").pressed then self.y = self.y - s end
	if Input("move_d").pressed then self.y = self.y + s end
end

function Mario:draw()
	--self.real_mario:draw()
	self.pieces:call("draw")
	
	Draw.setColor("green")
	local x, y = 100, 100
	local angle = math.rad(360*(mouse_x/game_width))
	local cx, cy = game_width/2, game_height/2
	x, y = x - cx, y - cy
	local newx = x * math.cos(angle) - y * math.sin(angle)
	local newy = x * math.sin(angle) + y * math.cos(angle)
	--Draw.circle("line",self.real_mario.x,self.real_mario.y,5)
	Draw.circle("line",newx+cx,newy+cy,10)
	Draw.setColor("red")
	--Draw.circle("line",self.real_mario.x + self.real_mario.xoffset,self.real_mario.y + self.real_mario.yoffset,5)
	Draw.reset("color")
end

--[[
local bob1 = Mario()
local bob2, bob3 = Mario(), Mario()
local bob4, bob5 = 1, 3
local bob6, bob7
]]