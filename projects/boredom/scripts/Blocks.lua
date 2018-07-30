BlankE.addEntity("MovingBlock")

function MovingBlock:init()	
	self.canvas = Canvas(self.scene_rect[3], self.scene_rect[4])
	self.canvas:drawTo(function()
		Draw.setColor("black")
		Draw.rect("line",
			0, 2,
			self.scene_rect[3], self.scene_rect[4]-4
		)
		Draw.rect("line",
			2, 0,
			self.scene_rect[3]-4, self.scene_rect[4]
		)
		Draw.rect("line",
			1, 1,
			self.scene_rect[3]-2, self.scene_rect[4]-2
		)
		Draw.rect("line", unpack(self.scene_rect))
		Draw.setColor("white")

		Draw.rect("fill",
			2, 2,
			self.scene_rect[3]-4, self.scene_rect[4]-4
		)
	end)
end

function MovingBlock:draw()
	self.canvas:draw(self.x, self.y)
end