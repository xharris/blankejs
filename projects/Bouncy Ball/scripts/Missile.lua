BlankE.addEntity("Missile")

function Missile:init()
	-- add missile image
	self.img_missile = Image("missile")
	-- center it
	self.img_missile.xoffset = self.img_missile.width / 2
	self.img_missile.yoffset = self.img_missile.height / 2
	
	-- after 10 seconds, stop homing in on the Paddle
	self.homing = true
	Timer.after(10, function()
		self.homing = false	
	end)
	
	-- give it a hitbox
	self:addShape("main","rectangle",{0,0,self.img_missile.width,self.img_missile.height})
end

function Missile:explode()
	
end

function Missile:update(dt)
	-- move it to the current position
	self.img_missile.x = self.x
	self.img_missile.y = self.y
	-- rotate the image to match the direction it's moving in
	self.img_missile.angle = self.direction
	-- if there is a paddle, move towards it
	local paddle = Paddle.instances[1]
	if paddle and self.homing then
		self:moveTowardsPoint(paddle.x, paddle.y, 400)
	end
	
	-- call our custom explode() method during a collision
	self.onCollision["main"] = function(other)
		if other.parent.classname == "Paddle" then
			self:explode()
		end
	end	
end

function Missile:draw()

end
