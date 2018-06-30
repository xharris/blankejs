BlankE.addEntity("IceBlock")

function IceBlock:init()
	bob = IceBlock()
end

function IceBlock:draw()
	Draw.setColor("black")
	Draw.rect('line', x, y, 100, 75)
end