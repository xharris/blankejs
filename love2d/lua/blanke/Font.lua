Font = Class{
	_fonts = {},

	init = function(self, options)
		self.options = {
			name = "console",
			image = '',
			characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
			size = 16,
			align = "left",
			limit = -1
		}
		if options then table.update(self.options, options) end

		self:_makeFontObj()

		_addGameObject("font",self)
	end,

	_makeFontObj = function(self)
		-- store the font for repeated uses
		local key = self.options.name..'-'..self.options.image..'-'..self.options.size
		if self.options.image == '' then
			Font._fonts[key] = love.graphics.newFont(Asset.font(self.options.name), self.options.size)
		else
			Font._fonts[key] = love.graphics.newImageFont(Asset.font(self.options.name), self.options.characters)
		end
		self.font = Font._fonts[key]
		return self
	end,

	use = function(self)
		love.graphics.setFont(self.font)
	end,

	getWidth = function(self, text)
		return self.font:getWidth(text)
	end,

	getHeight = function(self)
		return self.font:getHeight()
	end
}
return Font