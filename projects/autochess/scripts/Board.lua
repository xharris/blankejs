BlankE.addEntity("Board");

local SIZE = 8

function Board:init()
	self.penguins = Group()
	self.bench = Group()
	
	self.spaces = {}
	for i = 1, 8 do table.insert(self.spaces, {}) end
end

function Board:addPenguin(penguin)
	self.penguins:add(penguin)
	self.bench:add(penguin)
end

function Board:benchPenguin(penguin)
	
end

function Board:movePenguin(penguin, x, y)
	
end

function Board:draw()
	for x = 1, 8 do
		for y = 1, 8 do
			
		end
	end
end