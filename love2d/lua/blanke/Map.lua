-- for loading blankejs map into an array

Map = Class{
	init = function (self, name)
		self.array = {}
		self.layer_info = {}
		self.obj_info = {}

		local load_map = Asset.map(name)

		if load_map then
			return load_map
		end
	end,

	load = function(self, content)
		local data = json.decode(content)

		for i, layer_info in ipairs(data.layers) do
			self.layer_info[layer_info.name] = layer_info
		end

		for i, obj_info in ipairs(data.objects) do
			self.obj_info[obj_info.name] = obj_info

			-- store object coordinates
			for layer_name, coord_list in pairs(obj_info.coords) do
				-- layer name
				self.array[layer_name] = ifndef(self.array[layer_name], {})

				for c, coord in ipairs(coord_list) do
					local x, y = coord[1] / self.layer_info[layer_name].snap[1], coord[2] / self.layer_info[layer_name].snap[2]
					-- x
					self.array[layer_name][x] = ifndef(self.array[layer_name][x], {})
					-- y
					self.array[layer_name][x][y] = obj_info.char
				end
			end
		end

		return self
	end,

	-- returns list of [x,y] for object
	getObjects = function(self, ...)
		local ret_table = {}
		local names = {...}

		-- iterate give names
		for n, name in ipairs(names) do
			if self.obj_info[name] then
				-- iterate layers
				for layer_name, coord_list in pairs(self.obj_info[name].coords) do
					-- iterate object coordinate list
					for c, coord in ipairs(coord_list) do
						table.insert(ret_table, {
							x=coord[1], y=coord[2],
							name=name, char=self.obj_info[name].char
						})
					end
				end
			end
		end

		return ret_table
	end
}

return Map