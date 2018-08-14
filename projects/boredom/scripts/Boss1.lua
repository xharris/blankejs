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
	
	self.sleep_z
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
		end
	end	
end

function Boss1:draw()
	self:drawSprite()
	
	-- stage 0: draw Z's
	
end