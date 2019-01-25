Group = Class{
	init = function (self)
		self.children = {}
    	self.uuid = uuid()

		_prepareGameObject("group", self)
	end,

	__index = function(self, i)
		if type(i) == "number" then
			local children = rawget(self, "children")
			if i < 0 then i = #children + (i + 1) end
			return children[i]
		end
		return rawget(Group, i)
	end,

	add = function(self, ...)
		local objects = {...}
		for _, obj in ipairs(objects) do
			obj._group = ifndef(obj._group, {})
			obj._group[self.uuid] = self
			table.insert(self.children, obj)
		end
		return self
	end,

	get = function(self, i)
    	while i < 0 do
    		i = #self.children + (i + 1)
    	end
		if self.children[i] then
			return self.children[i]
		end
	end,

	-- key : find element i where i == key
	-- key, val : find element i where i[key] == val
	find = function(self, key, val)
		if val == nil then
			-- regular table search
			for i, v in ipairs(self.children) do
				if v == key then return i end
			end
			return 0
		else
			-- object search
			for i, v in ipairs(self.children) do
				if v[key] == val then return v, i end
			end
			return nil, 0
		end
	end,

	remove = function(self, o)
		if (type(o) == "number") then
			return table.remove(self.children, o)-- self.children[o] = nil
		elseif o.uuid then
			local i = 1
			while i <= #self.children do
				if self.children[i] and self.children[i].uuid and self.children[i].uuid == o.uuid then
					self:remove(i)
					return true
				end
				i = i + 1
			end
		end
	end,

	clear = function(self)
		local size = self:size()
		for i = 1, size do
			self:remove(i)
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
			obj._group[self.uuid] = nil
			if obj.destroy then obj:destroy() end
		end)
		self.children = {}
	end,

	-- for Entity only
	closestPoint = function(self, x, y)
		local min_dist = -1
		local min_ent

		for i_e, e in ipairs(self.children) do
			local dist = e:distancePoint(x, y)
			if min_dist == -1 or dist < min_dist then
				min_dist = dist
				min_ent = e
			end
		end

		return min_ent
	end,

	closest = function(self, ent)
		return self:closestPoint(ent.x, ent.y)
	end,

	size = function(self)
		return #self.children
	end,

	sort = function(self, attr, descending)
		local sort_fn = function (a, b) return a[attr] < b[attr] end
		if descending then sort_fn = function (a, b) return a[attr] > b[attr] end end
		table.sort(self.children, sort_fn)
	end
}

return Group