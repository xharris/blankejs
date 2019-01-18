BlankE.addEntity("Board");

local SIZE = 8

function Board:init()
	self.active_penguins = Group()
	self.benched_penguins = Group()
	
	
end

function Board:update(dt)
	
end

function Board:draw()
	self.active_penguins:call('draw')
	self.benched_penguins:call('draw')
end