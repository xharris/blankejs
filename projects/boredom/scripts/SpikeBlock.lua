BlankE.addEntity("SpikeBlock")

function SpikeBlock:init()
	self.img_spike = Image("spike")
	self.block_w = self.scene_rect[3] + (self.img_spike.width - (self.scene_rect[3] % self.img_spike.width))
	
	-- draw spikes
	self.canv_spike = Canvas(self.block_w, self.img_spike.height)
	self.canv_spike:drawTo(function()
		for x = 0, self.block_w, self.img_spike.width do
			self.img_spike:draw(x,0)	
		end
	end)
	
	-- death hitbox
	self:addShape("main","rectangle",{self.block_w,self.scene_rect[4],self.block_w,self.scene_rect[4]}, "ground.die")
end

function SpikeBlock:draw()
	self.canv_spike:draw(self.x, self.y)
	self:debugCollision()
end