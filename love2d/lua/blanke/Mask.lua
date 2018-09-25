Mask = Class{
	init = function(self, mask_type, func)
		self.fn = func
		self.mask_type = mask_type
		self.mask_val = 1
	end,

	on = function(self)
		if self.fn then
			love.graphics.stencil(self.fn, self.mask_type, self.mask_val)
			love.graphics.setStencilTest("greater", 0)
		end
	end,

	off = function(self)
		love.graphics.setStencilTest()
	end,
}

return Mask