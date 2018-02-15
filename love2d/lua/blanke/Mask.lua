Mask = Class{
	init = function(self, func, mask_type)
		self.func = func
		self.mask_type = mask_type
		self.mask_val = 1
	end,

	enable = function(self)
		love.graphics.stencil(self.func, self.mask_type, self.mask_val)
		love.graphics.setStencilTest("greater", 0)
	end,

	disable = function(self)
		love.graphics.setStencilTest()
	end,
}

return Mask