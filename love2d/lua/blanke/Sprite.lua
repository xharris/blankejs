Sprite = Class{
	init = function(self, args)
		self.x, self.y = 0, 0
		self.sprite_angle = 0		
		self.sprite_xscale = 1
		self.sprite_yscale = 1
		self.sprite_xoffset = 0
		self.sprite_yoffset = 0
		self.sprite_xshear = 0
		self.sprite_yshear = 0
		self.sprite_color = {255,255,255}
		self.sprite_alpha = 255
		self.sprite_speed = 1
		self.sprite_frame = 0
		self.sprite_width = 0
		self.sprite_height = 0

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

		self.onPropSet["sprite_frame"] = function(self, v) self.anim:gotoFrame(v) end

		_addGameObject("sprite",self)
	end,

	refreshSpriteDims = function(self)
		local anim_w, anim_h = self.anim:getDimensions()
		self.sprite_width, self.sprite_height = ifndef(anim_w, 0), ifndef(anim_h, 0)
	end,

	update = function(self, dt)
		self.anim:update(self.sprite_speed*dt)
		self.sprite_frame = self.anim.position
	end,

	draw = function(self,x,y)
		Draw.stack(function()
			local c = self.sprite_color
			Draw.setColor(c[1], c[2], c[3], ifndef(c[4], self.sprite_alpha))

			self.anim:draw(self.image(), math.floor(x or self.x), math.floor(y or self.y), math.rad(self.sprite_angle), 
				self.sprite_xscale, self.sprite_yscale, -math.floor(self.sprite_xoffset), -math.floor(self.sprite_yoffset), 
				self.sprite_xshear, self.sprite_yshear)
		end)
	end
}

return Sprite