BlankE.addEntity("Element")

local fnt_element = Font{size=34}

function Element:init()
	self.width = 50
	self.height = 50
	self.color = Draw.randomColor(1)
	self.index = 0
end

function Element:draw()
	Draw.setColor("blue")
	Draw.rect("line",self.x,self.y,self.width,self.height)
	fnt_element:draw(self.index, self.x, self.y)
end