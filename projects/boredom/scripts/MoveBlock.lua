BlankE.addEntity("MovingBlock")

function MovingBlock:init()	
	-- draw block
	Debug.log(unpack(self.scene_rect))
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
	
	self.coll_x, self.move_dir = nil, nil
end

function MovingBlock:update(dt)
	self.onCollision["main"] = function(other, sep)
		if other.tag == "ground" then
			self.coll_x = self.x + sep.point_x
		end
		
		if other.tag == "Player.feet_box" and self.hspeed == 0 then
			if not self.move_dir then
				if other.parent.x > self.coll_x then
					self.move_dir = "L"
				elseif other.parent.x < self.coll_x then
					self.move_dir = "R"
				end
			end
			if self.move_dir == "R" then
				self.move_tween = Tween(self, {hspeed=100}, 1, "quadratic in")
				self.move_tween:play()
			end
			if self.move_dir == "L" then
				self.move_tween = Tween(self, {hspeed=-100}, 1, "quadratic in")
				self.move_tween:play()
			end
		end
	end
	
	-- destroy when too far
	if (self.move_dir == "R" and self.coll_x < self.x) or
	   (self.move_dir == "L" and self.coll_x > self.x) then
		self:destroy()	
	end
end

function MovingBlock:draw()
		Draw.setColor("red")
	if self.move_dir == "R" then
		Draw.rect("line",self.x,self.y,self.coll_x-self.x+3,self.scene_rect[4])
		--Draw.crop(self.x,self.y,self.coll_x-self.x+3,self.scene_rect[4])
	elseif self.move_dir == "L" then
		Draw.rect("line", self.coll_x,self.y,self.scene_rect[3],self.scene_rect[4])
		-- Draw.crop(self.coll_x,self.y,self.scene_rect[3]-(self.coll_x-self.x),self.scene_rect[4])
	end
	--self.canvas:draw(self.x, self.y)
end