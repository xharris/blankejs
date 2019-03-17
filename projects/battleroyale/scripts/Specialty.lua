SPEC = {}

BlankE.addEntity("Specialty")

function Specialty:init(player, spec)
	self.player = player
	self.spec = spec
	self.spec.init(player)
end

function Specialty:update(dt)
	
end

function Specialty:draw()
	self.spec.draw()
end

function Specialty:doAction(num)
	if self.spec["action"..num] then
		self.spec["action"..num](self.player)
	end
end

function Specialty:click()
	if self.spec.click then
		self.spec.click(self.player)
	end
end