BlankE.addEntity("DoorBlock")

function DoorBlock:init()
	self.block = Block(self.scene_rect)
	self.block.x = self.x 
	self.block.y = self.y-2
	self.block.move_dir = "U"
	self.block.scene_rect[4] = self.scene_rect[4]+3
	
	self.img_button = Image("door_button")
	
	self:addShape("door_button","rectangle",{
		 	-(self.img_button.width*2),
			self.scene_rect[4],
			self.img_button.width, self.scene_rect[4]
	})
end

function DoorBlock:update(dt)
	self.onCollision["door_button"] = function(other, sep)
		if other.tag:contains("Player") and Input("action") then
			self.block.y = self.block.y - 0.75
		end
	end
end

function DoorBlock:draw()
	self.block:draw()
	self.img_button:draw(self.x-(self.img_button.width*1.5), self.y+self.scene_rect[4]-(self.img_button.height*1.5))
end