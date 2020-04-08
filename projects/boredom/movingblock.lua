Entity("MovingBlock", {
		images = { "block_corner.png" },
		align = "center",
		hitbox = true,
		default_reaction = 'cross',
		collision = function(self, v)
			if v.other.tag == "Player" and v.normal.y == -1 then 
				if not self.started then 
					self.started = true
					local mv_speed = 50
					switch(self.map_tag,{
						R = function() Tween(2, self, { hspeed = mv_speed }) end,
						L = function() Tween(2, self, { hspeed = -mv_speed }) end
					})
				end
			end
			if v.other.tag == "BlockDestroyer" then
				self:destroy()
			end
		end
})

Entity("BlockDestroyer", {
	hitbox=true,
	default_reaction = 'cross'
})0