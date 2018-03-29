BlankE.addClassType("DestructionWall", "Entity")

DestructionWall.net_sync_vars = {'x'}

function DestructionWall:init()
	self.hspeed = 0 -- 150
end

function DestructionWall:update(dt)

end

function DestructionWall:draw()
	--Draw.setColor('black')
	--Draw.line(self.x, main_view.top, self.x, main_view.bottom)
end