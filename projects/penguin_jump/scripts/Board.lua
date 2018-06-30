BlankE.addEntity("Board")

function Board:init()
	
end

BlankE.addEntity("IceBlock")
local block_width = 30

function IceBlock:init()
	
end

function IceBlock:draw()
	Draw.setColor("black")
	
	Draw.rect('line', self.x, self.y, block_width, block_width * .75)
end