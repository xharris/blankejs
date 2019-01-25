BlankE.addEntity("Penguin");

function Penguin:init()
	self.board_x = 0
	self.board_y = 0
end

function Penguin:update(dt)

end

function Penguin:draw()
	Draw.reset("color")
	Draw.setColor("blue")
	Draw.rect("fill",self.x, self.y, 30, 30)
end