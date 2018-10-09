Font = Class{
	_current_font = '',
	init = function(self, options)
		self.options = {
			name = "console.ttf",
			image = '',
			size = 12,
			align = "left",
			limit = -1
		}
		if options then
			for key, val in pairs(options) do self.options[key] = val end
		end

		self:_makeFontObj()
	end,

	_makeFontObj = function(self)
		if self.options.image == '' then
			self.font = love.graphics.newFont(self.options.name, self.options.size)
		else
			self.font = love.graphics.newImageFont(Asset.getInfo('image',self.options.image).path, self.options.characters)
		end
	end,

	_getOpt = function(self, key, override_opts)
		if override_opts and override_opts[key] then
			return override_opts[key]
		else
			return self.options[key]
		end
	end,

	set = function(self, key, val)
		self.options[key] = val
		if key == 'size' then
			self:_makeFontObj()	
		end
	end,

	get = function(self, key)
		if self.options[key] ~= nil then return self.options[key] end
	end,

	getWidth = function(self, text)
		return self.font:getWidth(text)
	end,

	draw = function(self, text, x, y, options) -- options can override font options
		local get = function(key) return self:_getOpt(key, options) end -- because im lazy

		local limit = get('limit')
		if limit <= 0 then limit = game_width - x end
 
		love.graphics.setFont(self.font)
		love.graphics.printf(ifndef(text, "nil"), x, y, limit, get('align'))
	end,
}

return Font