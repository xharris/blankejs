BlankE.addEntity("Penguin");

function Penguin:init()

end

function Penguin:update(dt)

end

function Penguin:draw()
	Draw.reset("color")
	Draw.setColor("blue")
	Draw.rect("fill",self.x, self.y, 30, 30)
end