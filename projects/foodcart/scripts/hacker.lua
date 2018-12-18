BlankE.addEntity("Hacker")

function Hacker:init()
	self.penguin = Penguin()
	self.penguin.x = game_width / 2
	self.penguin.y = game_height/ 2
	self.penguin.is_special = true
	self.move_speed = 160
end

function Hacker:update(dt)
	-- movement
	local dx, dy = 0, 0
	if Input("move_l").pressed then
		dx = dx - self.move_speed
	end
	if Input("move_r").pressed then
		dx = dx + self.move_speed
	end
	if Input("move_u").pressed then
		dy = dy - self.move_speed
	end
	if Input("move_d").pressed then
		dy = dy + self.move_speed
	end
	
	self.penguin.hspeed = dx
	self.penguin.vspeed = dy
	-- for z-ordering
	self.y = self.penguin.y
	
	local closest_npc = Npc.instances:closest(self)
	if closest_npc and self:distance(closest_npc) < 50 then
		--closest_npc.selected = true
	end
end

function Hacker:draw()
	self.penguin:draw()
end