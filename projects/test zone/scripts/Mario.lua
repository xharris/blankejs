BlankE.addEntity("Mario");

function Mario:init()
	self:addAnimation{name="mario_walk", image="sprite-example", frames={"1-3",1}, frame_size={31,44}, speed=0.2, offset={41,8}}
	self.sprite_index = "mario_walk"
end

function Mario:update(dt)

	local s = 2
	if Input("move_l").pressed then self.x = self.x - s end
	if Input("move_r").pressed then self.x = self.x + s end
	if Input("move_u").pressed then self.y = self.y - s end
	if Input("move_d").pressed then self.y = self.y + s end
end

--[[
local bob1 = Mario()
local bob2, bob3 = Mario(), Mario()
local bob4, bob5 = 1, 3
local bob6, bob7
]]