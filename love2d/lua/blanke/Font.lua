Font = Class{
	init = function(self, options)
		self.options = {
			size = 12,
			color = "white",
			align = "left",
			limit = -1
		}
		for key, val in pairs(options) do self.options[key] = val end

		self.font = love.graphics.newFont(self.options.size)
	end,

	_getOpt = function(self, key, override_opts)
		if override_opts and override_opts[key] then
			return override_opts[key]
		else
			return self.options[key]
		end
	end,

	set = function(self, key, val)
		if key == 'size' and self.options.size ~= val then
			self.font = love.graphics.newFont(val)
		end
		self.options[key] = val
	end,

	get = function(self, key)
		if self.options[key] ~= nil then return self.options[key] end
	end,

	draw = function(self, text, x, y, options) -- options can override font options
		local get = function(key) return self:_getOpt(key, options) end -- because im lazy

		local limit = get('limit')
		if limit <= 0 then limit = game_width - x end

		Draw.setColor(get('color'))
		love.graphics.setFont(self.font)
		love.graphics.printf(text, x, y, limit, get('align'))
	end,
}

return Font