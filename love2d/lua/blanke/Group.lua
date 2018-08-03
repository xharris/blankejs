local _views = {}
Group = Class{
	init = function (self)
		self.children = {}
	end,

	__index = function(self, i)
		if type(i) == "number" then
			return rawget(self, "children")[i]
		end
		return rawget(Group, i)
	end,

	add = function(self, obj)
		obj._group = self
		table.insert(self.children, obj)
	end,

	get = function(self, i)
		if self.children[i] then
			return self.children[i]
		end
	end,

	remove = function(self, i)
		if (type(i) == "number") then
			self.children[i] = nil
		elseif i.uuid then
			local i = 1
			while i <= #self.children do
				if self.children[i] and self.children[i].uuid and self.children[i].uuid == uuid then
					self:remove(i)
					--i = #self.children + 1
				end
				i = i + 1
			end
		end
	end,

	forEach = function(self, func)
		for i_c, c in ipairs(self.children) do
			if func(i_c, c) then break end
		end
	end,

	setProperty = function(self, attr, value)
		for i_c, c in ipairs(self.children) do
			if c[attr] then c[attr] = value end
		end
	end,

	call = function(self, func_name, ...)
		for i_c, c in ipairs(self.children) do
			if c[func_name] then c[func_name](c, ...) end
		end
	end,

	destroy = function(self)
		-- do a forEach to prevent infinite loop with _group var
		self:forEach(function(o, obj)
			obj._group = nil
			if obj.destroy then obj:destroy() end
		end)
		self.children = {}
	end,

	-- for Entity only
	closest_point = function(self, x, y)
		local min_dist, min_ent

		for i_e, e in ipairs(self.children) do
			local dist = e:distance_point(x, y)
			if dist < min_dist then
				min_dist = dist
				min_ent = e
			end
		end

		return min_ent
	end,

	closest = function(self, ent)
		return self:closest_point(ent.x, ent.y)
	end,

	size = function(self)
		return #self.children
	end,
}

return Group