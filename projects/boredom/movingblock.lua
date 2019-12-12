Entity("MovingBlock", {
	images = { "block_corner.png" },
	align = "center",
	hitbox = true,
	collTag = "oh",
	collList = {
		ground = 'cross'
	},
	collFilter = function(self, item, other)
		if other.tag == "Player" then
			self:move()
		end
	end,
	move = function(self)
		if not self.moving then
			self.moving = true	
		end
	end
})