BlankE.addEntity("Player")

local SPEED = 200

function Player:init()
	self.friction = 0.2
	self.aim_direction = 0
	self:addShape("main","rectangle",{0,0,20,20})
	
	self.my_img = Image("player_stand")
	
	Net.addObject(self)
end

function Player:update(dt)
	self:localOnly(function()
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
			Debug.log("released")
			self.spec:click()	
		end

		-- AIM
		local vw_main = View("main")
		self.aim_direction = direction(self.x,self.y,vw_main.mouse_x,vw_main.mouse_y)

		self.onCollision["main"] = function(other, sep)
			if other.tag == "ground" then
				self:collisionStop()
			end
			if other.tag:contains("explosion") then
				Debug.log("ow!")
			end
		end
	end)
end

function Player:draw()
	Draw.setColor("blue")
	local radius = 10
	Draw.rect("fill",self.x-radius, self.y-radius, radius*2, radius*2)
	Draw.reset('color')
	
	self.my_img.x = self.x 
	self.my_img.y = self.y
	self.my_img:draw()
end

function Player:setSpecialty(spec)
	self.spec = Specialty(self, SPEC[spec])
	if not self.net_object then self:netSync("setSpecialty",spec) end
end