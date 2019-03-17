BlankE.addEntity("Player")

local SPEED = 150

function Player:init()
	self.friction = 0.2
	self.aim_direction = 0
end

function Player:update(dt)
	-- MOVEMENT
	local dx, dy = 0, 0
	if Input("moveL").pressed then
		dx = dx - SPEED
	end
	if Input("moveR").pressed then
		dx = dx + SPEED
	end
	if Input("moveU").pressed then
		dy = dy - SPEED
	end
	if Input("moveD").pressed then
		dy = dy + SPEED
	end
	self.hspeed = dx
	self.vspeed = dy
	
	-- ACTIONS
	for a = 1, 3 do
		if self.spec and Input("action"..a).released then
			self.spec:doAction(a)
		end
	end
	if self.spec and Input("click").released then
		self.spec:click()	
	end
	
	-- AIM
	self.aim_direction = direction(self.x,self.y,mouse_x,mouse_y)
end

function Player:draw()
	Draw.setColor("blue")
	local radius = 20
	Draw.rect("fill",self.x-radius, self.y-radius, radius, radius)
	self.spec:draw()
end

function Player:setSpecialty(spec)
	self.spec = Specialty(self, spec)
end