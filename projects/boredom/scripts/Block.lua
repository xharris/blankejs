-- Block: sticks out of the ground and can move

BlankE.addEntity("Block")

function Block:init(rect)
	self.scene_rect = rect
	self.merge_ground = true
		
	local rw, rh = self.scene_rect[3], self.scene_rect[4]
	self:addShape("main","rectangle",{rw,rh,rw,rh}, "ground")
	
	self.coll_x, self.coll_y, self.move_dir = nil, nil, nil
end


function Block:update(dt)
	self.onCollision["main"] = function(other, sep)
		if other.tag == "ground" and not (self.coll_x or self.coll_y) then
			self.coll_x = self.x + sep.point_x
			self.coll_y = self.y + sep.point_y
		end
		
		if self.collisionCB then self:collisionCB(other, sep) end
	end
	
	-- destroy when too far
	if self.coll_x or self.coll_y then
		if (self.move_dir == "R" and self.x > self.coll_x) or
		   (self.move_dir == "L" and self.x + self.scene_rect[3] < self.coll_x) or
		   (self.move_dir == "U" and self.coll_y > self.y) or
		   (self.move_dir == "D" and self.coll_y < self.y) then
			self:destroy()	
		end
	end
end

function Block:draw()
	local x, y, w, h = self.x, self.y, self.scene_rect[3], self.scene_rect[4]
	if self.merge_ground and (self.coll_x or self.coll_y) then
		if self.move_dir == "R" then
			x, y, w, h = self.x,self.y,self.coll_x-self.x+3,self.scene_rect[4]
		elseif self.move_dir == "L" then
			x, y, w, h = self.coll_x-2,self.y,self.scene_rect[3]-(self.coll_x-self.x)+2,self.scene_rect[4]
		elseif self.move_dir == "U" then

		elseif self.move_dir == "D" then
			x, y, w, h = self.x,self.y,self.scene_rect[3],self.coll_y-self.y+2
		end
	end
	Draw.crop(x,y,w,h)
	
	Draw.setLineWidth(3)
	Draw.setColor("white")
	Draw.rect("fill",self.x,self.y,self.scene_rect[3],self.scene_rect[4])
	Draw.setColor("black")
	Draw.rect("line",self.x,self.y,self.scene_rect[3],self.scene_rect[4])	
end