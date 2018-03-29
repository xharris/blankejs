local _images = {}
 
Image = Class{
	init = function(self, name, img_data)
		self.name = name 

		if img_data and tostring(img_data):contains("ImageData") then
			self.image = love.graphics.newImage(img_data)
		else

			local asset = Asset.image(name)
			self.image = asset

			if asset == nil then
				error('Image not found: \"'..tostring(name)..'\"')
				return
			end
		end
		
		self.image:setWrap("clampzero","clampzero")
		self.image:setFilter("nearest")

		self.quad = nil
		self.x = 0
		self.y = 0
		self.angle = 0
		self.xscale = 1
		self.yscale = 1
		self.xoffset = 0
		self.yoffset = 0
		self.color = {255,255,255}
		self.alpha = 255

		self.orig_width = self.image:getWidth()
		self.orig_height = self.image:getHeight()
		self.width = self.orig_width * self.xscale
		self.height = self.orig_height * self.yscale
	end,

	-- static: check if an image exists
	exists = function(img_name)
		return Asset.has('image',img_name)
	end,

	setWidth = function(self, width)
		self.xscale = width / self.orig_width
		self.width = self.orig_width * self.xscale
		return self
	end,

	setHeight = function(self, height)
		self.yscale = height / self.orig_height
		self.height = self.orig_height * self.yscale
		return self
	end,

	setSize = function(self, width, height)
		self.setWidth(width)
		self.setHeight(height)
	end,

	setScale = function(self, x, y)
		if not y then y = x end
		self.xscale = x
		self.width = self.orig_width * self.xscale
		self.yscale = y
		self.height = self.orig_height * self.yscale
	end,

	draw = function(self, x, y)
		self.width = self.orig_width * self.xscale
		self.height = self.orig_height * self.yscale

		x = ifndef(x, self.x)
		y = ifndef(y, self.y)

		love.graphics.push()
		love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)	
		if self.quad then
			love.graphics.draw(self.image, self.quad, x, y, math.rad(self.angle), self.xscale, self.yscale, self.xoffset, self.yoffset, self.xshear, self.yshear)
		else
			love.graphics.draw(self.image, x, y, math.rad(self.angle), self.xscale, self.yscale, self.xoffset, self.yoffset, self.xshear, self.yshear)
		end
		love.graphics.pop()
		return self
	end,

	tileX = function(self, w)
		w = ifndef(w, game_width)
		for x = self.x, w, self.width do
			if x < w then
				self:draw(x, self.y)
			end
		end
	end,

	tileY = function(self, h)
		h = ifndef(h, game_height)
		for y = self.y, h, self.height do
			if y < h then
				self:draw(self.y, y)
			end
		end
	end,

	tile = function(self, w, h)
		w = ifndef(w, game_width)
		h = ifndef(h, game_height)
		for x = self.x, w, self.width do
			for y = self.y, h, self.height do
				if x < w and y < h then
					self:draw(x,y)
				end
			end
		end
	end,

    __call = function(self)
    	return self.image
	end,

	-- break up image into pieces
	chop = function(self, piece_w, piece_h)
		piece_w = math.ceil(piece_w)
		piece_h = math.ceil(piece_h)

		local img_list = {}
		local new_quad = love.graphics.newQuad(0,0,piece_w,piece_h, self.image:getDimensions())
		for x=0, self.orig_width, piece_w do
			for y=0, self.orig_height, piece_h do
				if x < self.orig_width or y < self.orig_height then
					local new_image = self:crop(x,y,piece_w,piece_h)
					new_image.x = self.x + x
					new_image.y = self.y + y
					table.insert(img_list, new_image)
				end
			end
		end
		return img_list
	end,

	crop = function(self, x, y, w, h)
		local src_image_data = self.image:getData()
		local dest_image_data = love.image.newImageData(w,h)
		dest_image_data:paste(src_image_data, 0, 0, x, y, w, h)

		return Image(self.name, dest_image_data)
	end,

	combine = function(self, other_image)
		local src_image_data = other_image.image:getData()
		local dest_image_data = self.image:getData()

		dest_image_data:mapPixel(function(x,y,r,g,b,a)
			local sr, sg, sb, sa = src_image_data:getPixel(x,y)
			if sa > 0 then
				return
					(r * a / 255) + (sr * sa * (255 - a) / (255*255)),
					(g * a / 255) + (sg * sa * (255 - a) / (255*255)),
					(b * a / 255) + (sb * sa * (255 - a) / (255*255)),
					a + (sa * (255 - a) / 255)
			else
				return r, g, b, a
			end
		end)

		self.image = love.graphics.newImage(dest_image_data)
	end,

	frame = function(self, f, width, height, space_x, space_y)
		space_x = ifndef(space_x, 0)
		space_y = ifndef(space_y, 0)

		local rows, columns = math.floor(self.height/height), math.floor(self.width/width)
		
		local x = math.floor(f % columns)
		local y = math.floor(f / rows)

		if x >= columns then x = columns - 1 end
		if y >= rows then y = rows - 1 end
	
		x = x * (width+space_x)
		y = y * (height+space_y)

		return self:crop(x, y, width, height)
	end,
}

return Image