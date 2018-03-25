BlankE.addClassType("FragImage", "Entity")

frag_images = {}

function FragImage:init(image)
	if image.alpha == 0 then self:destroy() else

		self.img_frags = image:chop(image.width/randRange(3,5),image.width/randRange(3,5))

		-- add gravity to images
		table.forEach(self.img_frags, function(f, frag)
			frag.random_g = randRange(7,10)
			frag.gravity = 0
		end)

		table.insert(frag_images, self)
	end
end

function FragImage:update(dt)	
	local wall_x = 0
	if wall then wall_x = wall.x end

	local drawn = 0
	table.forEach(self.img_frags, function(f, frag)
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
		self:destroy()
	end
end

function FragImage:draw()
	for f, frag in ipairs(self.img_frags) do
		frag:draw()
	end
end

FragImage.drawAll = function()
	for f, frag_image in ipairs(frag_images) do
		frag_image:draw()
	end
end