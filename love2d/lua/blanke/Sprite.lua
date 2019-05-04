local floor = function(v) return math.floor(v) end

Sprite = Class{
	_vars = {'angle','xscale','yscale','xoffset','yoffset','xshear','yshear','alpha','speed','frame','width','height','color'},
	init = function(self, args)
		self.x, self.y = 0, 0
		self.angle = 0		
		self.xscale = 1
		self.yscale = 1
		self.xoffset = 0
		self.yoffset = 0
		self.xshear = 0
		self.yshear = 0
		self.color = {255,255,255}
		self.alpha = 255
		self.speed = 1
		self.frame = 0
		self.width = 0
		self.height = 0

		table.update(self, args)

		-- main args
		local name = args.image
		local frames = ifndef(args.frames, {1,1})
		-- other args
		local offset = ifndef(args.offset, {0,0})
		local left = offset[1]
		local top = offset[2]
		local border = ifndef(args.border, 0)
		local speed = ifndef(args.speed, 0.1)

		if Image.exists(name) then
			-- spritesheet
			if args.frame_size then
				self.is_animated = true
				self.image = Image(name)
				local frame_size = ifndef(args.frame_size, {self.image.width, self.image.height})
				local grid = anim8.newGrid(frame_size[1], frame_size[2], self.image.width, self.image.height, left, top, border)
				self.anim = anim8.newAnimation(grid(unpack(frames)), speed)
				self.frame_count = table.len(self.anim.frames)
				self.duration = self.anim.totalDuration

			-- regular image
			else
				self.is_animated = false
				self.image = Image(name)
			end

			self:refreshSpriteDims()
		end

		-- calculate alingment
		if args.align then 
			Debug.log(args.name, args.align)
			local centered = false
			if args.align:contains("center") then
				centered = true
				self.xoffset = self.xoffset + (self.width / 2)
				self.yoffset = self.yoffset + (self.height / 2)
			end
			if args.align:contains("left") and centered then
				self.xoffset = self.xoffset - (self.width / 2)
			end
			if args.align:contains("right") then
				self.xoffset = self.xoffset + self.width
			end
			if args.align:contains("top") then
				self.yoffset = self.yoffset - (self.height / 2)
			end
			if args.align:contains("bottom") then
				self.yoffset = self.yoffset + self.height
			end
			Debug.log(self.xoffset, self.yoffset, self.width, self.height)
		end 

		_addGameObject("sprite",self)
	end,

	refreshSpriteDims = function(self)
		if self.is_animated then
			local anim_w, anim_h = self.anim:getDimensions()
			self.width, self.height = ifndef(anim_w, 0), ifndef(anim_h, 0)
		else 
			self.width = self.image.width 
			self.height = self.image.height 
		end
	end,

	update = function(self, dt)
		if self.is_animated then 
			self.anim:update(self.speed*dt)
			self.frame = self.anim.position
		else 

		end 
	end,

	debug = function(self)
		Draw.stack(function()
			Draw.translate(self.x, self.y)
			Draw.rotate(self.angle)
			Draw.shear(self.xshear, self.yshear)
			Draw.scale(self.xscale, self.yscale)

			-- draw sprite outline
			Draw.setColor(0,1,0,2/3)
			Draw.setLineWidth(1)
			
			love.graphics.rectangle("line", self.xoffset, self.yoffset, self.width, self.height)
			
			-- draw origin point
			Draw.setColor(0,0,0,2/3)
			love.graphics.circle("line", 0, 0, 2)
			Draw.setColor(0,1,0,2/3)
			love.graphics.circle("line", 0, 0, 2)
		end)
	end,

	getImage = function(self)
		if self.is_animated then 
			return self.image:crop(self.anim.frames[self.frame]:getViewport())
		else 
			return self.image 
		end 
	end,

	draw = function(self,options,x,y)
		options = options or {}
		function o(key) return options[key] or self[key] end

		self.speed = o('speed')

		-- drawing a certain frame
		if self.is_animated and o('speed') == 0 and o('frame') ~= 0 then
			self.anim:gotoFrame(o('frame'))
		end

		Draw.stack(function()
			local c = Draw._parseColorArgs(o('color'))
			Draw.setColor(c[1], c[2], c[3], ifndef(c[4], o('alpha')))

			if self.is_animated then 
				self.anim:draw(self.image(), floor(x or self.x), floor(y or self.y), math.rad(o('angle')), 
					o('xscale'), o('yscale'), floor(self.xoffset + o('xoffset')), floor(self.yoffset + o('yoffset')), 
					o('xshear'), o('yshear'))
			else 
				for p, prop in ipairs(Sprite._vars) do 
					if prop == 'xoffset' or prop == 'yoffset' then 
						self.image[prop] = self[prop] + o(prop)
					else 
						self.image[prop] = o(prop)
					end
				end 
				self.image.x = floor(x or self.x)
				self.image.y = floor(y or self.y)
				self.image:draw()
			end
		end)
	end
}

return Sprite