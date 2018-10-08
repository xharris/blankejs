Mask = Class{
	init = function(self, mask_type, func)
		self.fn = func
		self.mask_type = mask_type
		self.mask_val = 1
		self.test_type = "less"
		self.test_value = 1
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
	end
}

return Mask