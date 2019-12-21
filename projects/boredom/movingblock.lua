Entity("MovingBlock", {
		images = { "block_corner.png" },
		align = "center",
		hitbox = true,
		defaultCollRes = 'cross',
		collision = function(self, v)
			if v.other.tag == "Player" and v.normal.y == -1 then 
				self.moving = true
			end
			if v.other.tag == "BlockDestroyer" then
				self:destroy()
			end
		end,
		update = function(self, dt)
			if self.moving and not self.started then 
				self.started = true
				local mv_speed = 50
				switch(self.mapTag,{
					R = function() Tween(2, self, { hspeed = mv_speed }) end,
					L = function() Tween(2, self, { hspeed = -mv_speed }) end
				})
			end
		end
})

Entity("BlockDestroyer", {
	hitbox=true
})