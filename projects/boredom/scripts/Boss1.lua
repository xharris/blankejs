BlankE.addEntity("Boss1")

function Boss1:init()
	self:addAnimation{
		name="sleep",
		image="boss1_sleep"
	}
	self.x = self.scene_rect[1]
	self.y = self.scene_rect[2]
	self.gravity = 20
	
	self:addShape("main","rectangle",{
			self.sprite_width, self.sprite_height+10,
			self.sprite_width, self.sprite_height-10
	})			
	self:setMainShape("main")
	
end

function Boss1:update(dt)
	self.onCollision["main"] = function(other, sep)
		if other.tag == "ground" then
			self:collisionStopY()
		end
	end
end