local _images = {}
 
Image = Class{
	_canvas = nil,
	init = function(self, name, img_data)
		if not Image._canvas and Canvas then Image._canvas = Canvas() end

		name = cleanPath(name)
		self.name = name 

		local asset = Asset.image(name)

		if img_data and tostring(img_data):contains("ImageData") then
			self.image = love.graphics.newImage(img_data)

		elseif asset then
			self.image = asset

		elseif getFileInfo(name) then
			self.image = Asset.add(name)

		end

		assert(self.image, 'Image not found: \"'..tostring(name)..'\"')

		self.image:setWrap("clampzero","clampzero")
		self.quad = nil

		self.x = 0
		self.y = 0
		self.angle = 0
		self.xscale = 1
		self.yscale = 1
		self.xoffset = 0
		self.yoffset = 0
		self.color = {1,1,1}
		self.alpha = 1
		self.int_position = true

		self.orig_width = self.image:getWidth()
		self.orig_height = self.image:getHeight()
		self.width = self.orig_width * math.abs(self.xscale)
		self.height = self.orig_height * math.abs(self.yscale)
		self.crop_rect = {0,0,self.orig_width,self.orig_height}
	end,

	destroy = function(self)
		self.image:release()
	end,

	-- static: check if an image exists
	exists = function(img_name)
		return Asset.has('image',img_name)
	end,

	setWidth = function(self, width)
		self.xscale = width / self.orig_width
		self.width = self.orig_width * math.abs(self.xscale)
		return self
	end,

	setHeight = function(self, height)
		self.yscale = height / self.orig_height
		self.height = self.orig_height * math.abs(self.yscale)
		return self
	end,

	setSize = function(self, width, height)
		self.setWidth(width)
		self.setHeight(height)
	end,

	setScale = function(self, x, y)
		if not y then y = x end
		self.xscale = x
		self.width = self.orig_width * math.abs(self.xscale)
		self.yscale = y
		self.height = self.orig_height * math.abs(self.yscale)
	end,

	draw = function(self, x, y)
		self.width = self.orig_width * math.abs(self.xscale)
		self.height = self.orig_height * math.abs(self.yscale)

		x = ifndef(x, self.x)
		y = ifndef(y, self.y)

		if self.int_position then
			x = math.floor(x)
			y = math.floor(y)
		end

		Draw.stack(function()
			love.graphics.setColor(Draw._parseColorArgs(self.color[1], self.color[2], self.color[3], self.alpha))	
			if self.quad then
				love.graphics.draw(self.image, self.quad, x, y, math.rad(self.angle), self.xscale, self.yscale, self.xoffset, self.yoffset, self.xshear, self.yshear)
			else
				love.graphics.draw(self.image, x, y, math.rad(self.angle), self.xscale, self.yscale, self.xoffset, self.yoffset, self.xshear, self.yshear)
			end
		end)
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
	_copy_props = {'x','y','angle','xscale','yscale','color','alpha','int_position'},
	chop = function(self, columns, rows)
		piece_w = math.ceil(self.width / columns)
		piece_h = math.ceil(self.height / rows)

		local img_list = Group()
		local new_x, new_y
		for x=0, self.crop_rect[3], piece_w do
			for y=0, self.crop_rect[4], piece_h do
				if x < self.crop_rect[3] or y < self.crop_rect[4] then
					local new_image = self:crop(x,y,piece_w,piece_h)	
					for i,k in ipairs(Image._copy_props) do
						new_image[k] = self[k]
					end

					new_x = (x-self.xoffset)*math.cos(math.rad(self.angle)) - (y-self.yoffset)*math.sin(math.rad(self.angle))
					new_y = (x-self.xoffset)*math.sin(math.rad(self.angle)) + (y-self.yoffset)*math.cos(math.rad(self.angle))

					new_image.x = new_x + self.x 
					new_image.y = new_y + self.y 

					img_list:add(new_image)
				end
			end
		end
		return img_list
	end,

	crop = function(self, x, y, w, h)
		local new_img = Image(self.name)
		new_img.crop_rect = {x,y,w,h}
		new_img.quad = love.graphics.newQuad(x,y,w,h,self.orig_width,self.orig_height)
		return new_img
	end,

	combine = function(self, other_image)
		local src_image_data = Asset.getInfo("image",other_image.name).image_data
		local dest_image_data = Asset.getInfo("image",self.name).image_data -- love.image.newImageData(Asset.getInfo('image', self.name).path)
		
		local uncropped_dest_image_data = love.image.newImageData(Asset.getInfo('image', self.name).path)
		local dest_image_data = love.image.newImageData(self.crop_rect[3], self.crop_rect[4])
		dest_image_data:paste(uncropped_dest_image_data, 0, 0, self.crop_rect[1], self.crop_rect[2], self.crop_rect[3], self.crop_rect[4])

		local src_w = math.min(self.width, other_image.width)
		local src_h = math.min(self.height, other_image.height)

		dest_image_data:mapPixel(function(x,y,r,g,b,a)
			--if x >= src_w or y >= src_h then return 0,0,0,0 end

			local sr, sg, sb, sa = src_image_data:getPixel(x,y)
			if sa > 0 then
				return
					(r * a / 1) + (sr * sa * (1 - a) / 1),
					(g * a / 1) + (sg * sa * (1 - a) / 1),
					(b * a / 1) + (sb * sa * (1 - a) / 1),
					a + (sa * (1 - a) / 1)
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