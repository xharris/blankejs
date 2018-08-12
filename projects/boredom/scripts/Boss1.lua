BlankE.addEntity("Boss1")

function Boss1:init()
	self:addShape("main","rectangle",{
		self.scene_rect[3],self.scene_rect[4],
		self.scene_rect[3],self.scene_rect[4]
	})
			
	self.show_debug = true
end