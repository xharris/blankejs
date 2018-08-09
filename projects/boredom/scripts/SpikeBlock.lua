BlankE.addEntity("SpikeBlock")

function SpikeBlock:init()
	self.img_spike = Image("spike")
	self.block_w = self.scene_rect[3] + (self.img_spike.width - (self.scene_rect[3] % self.img_spike.width))
	self.block_h = self.scene_rect[4] + (self.img_spike.width - (self.scene_rect[4] % self.img_spike.width))
	self.activated = false
	self.start_y = self.y
	
	if self.scene_tag == "U" then
		self.block = Block({0,0,self.scene_rect[3],2})
		self.canv_spike = Canvas(self.block_w, self.img_spike.height)
	elseif self.scene_tag == "R" then
		self.img_spike.xoffset = self.img_spike.width/2
		self.img_spike.yoffset = self.img_spike.height/2
		self.img_spike.angle = 90
		
		self.block = Block({self.scene_rect[3]-2,0,2,self.scene_rect[4]})
		self.canv_spike = Canvas(self.img_spike.height, self.block_h)
	end
		
	self.block.merge_ground = false
	
	-- draw spikes
	self.canv_spike:drawTo(function()
		if self.scene_tag == "U" then
			for x = 0, self.block_w, self.img_spike.width do
				self.img_spike:draw(x,0)	
			end
		elseif self.scene_tag == "R" then
			for y = 0, self.block_h, self.img_spike.width do
				self.img_spike:draw(0,y)
			end
		end
	end)
	
	-- death hitbox
	self:addShape("main","rectangle",{self.block_w,self.scene_rect[4],self.block_w,self.scene_rect[4]}, "ground.die")
end

function SpikeBlock:update(dt)
	-- player steps into activation zone
	local player = Player.instances[1]
	if not self.activated and player then
		if self.scene_tag == "U" then
			if player.x > self.x and player.x < self.x+self.block_w and player.y < self.y and player.x > self.y - 64 then
				self.activated = true
				self.move_tween = Tween(self, {vspeed=-180}, 3, "linear")
				self.move_tween:play()
			end			
		end
	end
	
	self.onCollision["main"] = function(other, sep)
		if other.tag == "spike_blockStop" then
			self.move_tween:stop()
			if self.scene_tag == "U" then self.vspeed = 0 end
		end
	end
end

function SpikeBlock:draw()
	self.canv_spike:draw(self.x-1, self.y-self.img_spike.height+1)
	self.block.x = self.x 
	self.block.y = self.y
	self.block.scene_rect[4] = self.start_y - self.y + 2
	
	self.block:draw()
end