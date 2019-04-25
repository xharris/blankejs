Sprite = Class{
	_vars = {'angle','xscale','yscale','xoffset','yoffset','xshear','yshear','color',
	'alpha','speed','frame'},
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
			self.image = Image(name)
			local frame_size = ifndef(args.frame_size, {self.image.width, self.image.height})
		    local grid = anim8.newGrid(frame_size[1], frame_size[2], self.image.width, self.image.height, left, top, border)
			self.anim = anim8.newAnimation(grid(unpack(frames)), speed)
			self.frame_count = table.len(self.anim.frames)
			self.duration = self.anim.totalDuration

			self:refreshSpriteDims()
		end

		--self.onPropSet["frame"] = function(v) self.anim:gotoFrame(v) end

		_addGameObject("sprite",self)
	end,

	refreshSpriteDims = function(self)
		local anim_w, anim_h = self.anim:getDimensions()
		self.width, self.height = ifndef(anim_w, 0), ifndef(anim_h, 0)
	end,

	update = function(self, dt)
		self.anim:update(self.speed*dt)
		self.frame = self.anim.position
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
			if self._sprites[sprite_index] then
				love.graphics.rectangle("line", self.xoffset, self.yoffset, self.width, self.height)
			end
			-- draw origin point
			Draw.setColor(0,0,0,2/3)
			love.graphics.circle("line", 0, 0, 2)
			Draw.setColor(0,1,0,2/3)
			love.graphics.circle("line", 0, 0, 2)
		end)
	end,

	draw = function(self,x,y)
		-- drawing a certain frame
		if self.speed == 0 and self.frame ~= 0 then
			self.anim:gotoFrame(self.frame)
		end

		Draw.stack(function()
			local c = self.color
			Draw.setColor(c[1], c[2], c[3], ifndef(c[4], self.alpha))

			self.anim:draw(self.image(), math.floor(x or self.x), math.floor(y or self.y), math.rad(self.angle), 
				self.xscale, self.yscale, -math.floor(self.xoffset), -math.floor(self.yoffset), 
				self.xshear, self.yshear)
		end)
	end
}

return Sprite