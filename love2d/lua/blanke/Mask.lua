Mask = Class{
	_image_shader = love.graphics.newShader[[
   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }
]],
	_image_alpha_shader = love.graphics.newShader[[
   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      if (Texel(texture, texture_coords).a == 0.0) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }
]],
	init = function(self, options)
		self.fn = func
		self.mask_type = "replace"
		self.mask_val = 1 
		self.test_type = "less" 
		self.test_value = 1 

		table.update(self, options)

		self.use_image_mask = false
	end,

	-- set predefined values
	setup = function(self, val)
		if val == "inside" then
			self.test_type = "greater"
			self.test_value = 0
		end
		if val == "outside" then
			self.test_type = "less"
			self.test_value = 1
		end
	end,

	on = function(self)
		if self.fn then
			love.graphics.stencil(self.fn, self.mask_type, self.mask_val)
			love.graphics.setStencilTest(self.test_type, self.test_value)
		end
	end,

	off = function(self)
		love.graphics.setStencilTest()
	end,

	draw = function(self, fn)
		self:on()
		fn()
		self:off()
	end,

	_useMask = function(self, mask_name, image, fn)
		love.graphics.setShader(Mask[mask_name])
		image:draw()
		if fn then fn() end
		love.graphics.setShader()
	end,

	useImageMask = function(self, image, fn) self:_useMask("_image_shader", image, fn) end,
	useImageAlphaMask = function(self, image, fn) self:_useMask("_image_alpha_shader", image, fn) end
}

return Mask