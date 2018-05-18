BlankE.addEntity("FragImage")

frag_images = Group()

function FragImage:init(image, parent)
	if image.alpha == 0 then self:destroy() else
		self.parent = parent
		
		self.img_frags = image:chop(image.width/randRange(3,5),image.width/randRange(3,5))

		-- add gravity to images
		self.img_frags:forEach(function(f, frag)
			frag.random_g = randRange(7,10)
			frag.gravity = 0
		end)

		frag_images:add(self)
	end
end

function FragImage:update(dt)	
	local wall_x = 0
	if wall then wall_x = wall.x end

	local drawn = 0
	self.img_frags:forEach(function(f, frag)
		if wall_x > frag.x + (frag.random_g*5) then
			frag.gravity = frag.gravity + frag.random_g
			frag.y = frag.y + frag.gravity * dt
			frag.x = frag.x - 15 * dt
		end
			
		if frag.y < main_view.bottom then
			drawn = drawn + 1		
		end
	end)
	
	-- are all the frags destroyed?
	if drawn == 0 then
		self.img_frags:destroy()
		self:destroy()
		if self.parent then self.parent:destroy() end
	end
end

function FragImage:draw()
	if self.img_frags then
		self.img_frags:forEach(function(f, frag)
			frag:draw()
		end)
	end
end

FragImage.drawAll = function()
	frag_images:forEach(function(f, obj)
		obj:draw()
	end)
end