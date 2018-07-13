BlankE.addEntity("DestructionWall")

DestructionWall.net_sync_vars = {'x'}

function DestructionWall:init()
	self.hspeed = 150
end

function DestructionWall:update(dt)

end

function DestructionWall:draw()
	Draw.setColor('red')
	Draw.line(self.x, main_view.top, self.x, main_view.bottom)
end