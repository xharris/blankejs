BlankE.addEntity("MovingBlock")

function MovingBlock:init()	
	-- draw block
	self.canvas = Canvas(self.scene_rect[3], self.scene_rect[4])
	self.canvas:drawTo(function()
		Draw.setColor("black")
		Draw.rect("line",
			0, 2,
			self.scene_rect[3], self.scene_rect[4]-4
		)
		Draw.rect("line",
			2, 0,
			self.scene_rect[3]-4, self.scene_rect[4]
		)
		Draw.rect("line",
			1, 1,
			self.scene_rect[3]-2, self.scene_rect[4]-2
		)
		Draw.rect("line", unpack(self.scene_rect))
		Draw.setColor("white")
		Draw.rect("fill",
			2, 2,
			self.scene_rect[3]-4, self.scene_rect[4]-4
		)
	end)
	
	local rw, rh = self.scene_rect[3], self.scene_rect[4]
	self:addShape("main","rectangle",{rw,rh,rw,rh}, "ground")
	
	self.coll_x, self.coll_y, self.move_dir = nil, nil, nil
end

function MovingBlock:update(dt)
	self.onCollision["main"] = function(other, sep)
		if other.tag == "ground" then
			-- get 
			if not self.move_dir then
				self.coll_x = self.x + sep.point_x
				self.coll_y = self.y + sep.point_y
				if self.coll_x > self.x then self.move_dir = "R" end
				if self.coll_x < self.x then self.move_dir = "L" end
			end
		end
		
		if other.tag == "Player.feet_box" then
			if self.move_dir == "R" then
				self.hspeed = 50
			end
			if self.move_dir == "L" then
				self.hspeed = -50
			end
			Debug.log(self.hspeed)
		end
	end
end

function MovingBlock:draw()
	Draw.crop(self.x,self.y,self.coll_x-self.x,self.scene_rect[4])
	self.canvas:draw(self.x, self.y)
end