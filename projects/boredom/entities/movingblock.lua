Entity("MovingBlock", {
	image = "block_corner.png",
	align = "center",
	hitbox='ground',
	vel = {0,0},
	collision = function(self, v, other_tag, other_cname)
	  if other_tag == "living" and v.normal.y == -1 then 
		if not self.started then 
		  self.started = true
		  local mv_speed = 50
		  switch(self.map_tag,{
			  R = function() Tween(2, self, { vel = {mv_speed , 0} }) end,
			  L = function() Tween(2, self, { vel = {-mv_speed , 0} }) end
		  })
		end
	  end
	  if other_cname == "BlockDestroyer" then
		Destroy(self)
	  end
	end
})

Entity("BlockDestroyer", {
	hitbox=true
})

Game.debug = true