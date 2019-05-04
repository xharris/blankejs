BlankE.addEntity("Missile")

function Missile:init()
	-- add missile image
	self:addSprite{name="main",image="missile",align="center"}
	-- make the missile non-homing when it spawns
	self.homing = false
	-- have the missile fade in while it's "charging up"
	self.sprite_alpha = 0
	-- at the end of the tween, set the missile to homing
	Tween(self, {sprite_alpha=1}, 1, "linear", function()
		-- at the end of the tween, set the missile to homing
		self.homing = true
		Timer.after(10, function()
			self.homing = false
		end)
	end):play()
	
	-- give it a hitbox
	self:addShape("main","rectangle")
end

function Missile:explode()
	-- break the missile image into pieces
	self.img_missile_pcs = self:getImage():chop(5,5)
	-- throw them in the opposite direction 
	local opp_direction = self.sprite_angle + 180
	self.img_missile_pcs:forEach(function(piece)
		local direction = randRange(opp_direction - 45, opp_direction + 45)
		piece.hspeed = direction_x(direction, 20)
		piece.vspeed = direction_y(direction, 20)
	end)
	-- draw the pieces
	if self.img_missile_pcs then
		self.img_missile_pcs:call('draw')
	end
	-- remove the hitbox so that it seems like it's actually exploded and gone
	self:removeShape("main")
	-- after some time, destroy the object
	Timer.after(3, function()
		self:destroy()
	end)
end

function Missile:update(dt)
	-- rotate the image to match the direction it's moving in
	self.sprite_angle = self.direction + 90
	
	-- if there is a paddle, move towards it
	local paddle = Paddle.instances[1]
	if paddle and self.homing then
		self:moveTowards(paddle, 100)
	end
	
	-- call our custom explode() method during a collision
	self.onCollision["main"] = function(other)
		if other.parent.classname == "Paddle" and self.homing then
			self:explode()
			other.parent:explode()
		end
	end	
end

function Missile:draw()
	-- draw the pieces
	-- hide the old image if it's exploded
	if self.img_missile_pcs then
		self.img_missile_pcs:call('draw')
	else
		self:drawSprite()
	end
end
