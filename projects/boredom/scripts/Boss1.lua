BlankE.addEntity("Boss1")

local player

function Boss1:init()
	self.stage = 0
	--[[ 
	0 - asleep
	1 - 4: NOT asleep (wow)
	]]
	
	self:addAnimation{
		name="sleep",
		image="boss1_sleep"
	}
	self:addAnimation{
		name="idle",
		image="boss1_idle"
	}
	self.x = self.scene_rect[1]
	self.y = self.scene_rect[2]
	self.gravity = 20
	
	self:addShape("main","rectangle",{
			self.sprite_width, self.sprite_height+10,
			self.sprite_width, self.sprite_height-10
	})			
	self:setMainShape("main")
	self.sprite_index = "sleep"
	
	-- stage 0 
	self.z_canvas = Canvas(30, 30)
	self.z_canvas:drawTo(function()
		Draw.setColor("black")
		Draw.text("Z",0,0)
	end)
	self.y_canvas = Canvas(30, 30)
	self.y_canvas:drawTo(function()
		Draw.setColor("black")
		Draw.text("Y",0,0)
	end)
	self.sleep_z = Repeater(self.z_canvas,{
		x = self.x + 5,
		y = self.y + 10,
		linear_accel_x = -10,
		linear_accel_y = -10,
		end_color = {1,1,1,0}
	})
end

function Boss1:update(dt)
	player = Player.instances[1]
	
	self.onCollision["main"] = function(other, sep)
		if other.tag == "ground" then
			self:collisionStopY()
		end
	end
	
	if self.stage == 0 and player then
		if self:distance(player) < 35 then
			self.sprite_index = "idle"
			self.stage = 1
		end
	end	
end

function Boss1:draw()
	self:drawSprite()
		
	-- stage 0: draw Z's
	if self.stage == 0 then
		self.sleep_z:draw()
	elseif self.stage == 1 then
	-- stage 1: waking up
		self.sleep_z:draw()
		self.sleep_z:setTexture(self.y_canvas)
	end
end