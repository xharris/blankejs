-- special type of hashtable that groups objects with similar coordinates
local Scenetable = Class{
	init = function(self, mod_val)
		self.mod_val = ifndef(mod_val, 32)
		self.data = {}
	end,
	hash = function(self, x, y)
		return tostring(x - (x % self.mod_val))..','..tostring(y - (y % self.mod_val))
	end,
	hash2 = function(self, obj)
		return tostring(obj)
	end,
	add = function(self, x, y, obj)
		local hash_value = self:hash(x, y)
		local hash_obj = self:hash2(obj)

		self.data[hash_value] = ifndef(self.data[hash_value], {})
		self.data[hash_value][hash_obj] = obj
	end,
	-- returns a table containing all objects at a coordinate
	search = function(self, x, y) 
		local hash_value = self:hash(x, y)
		return ifndef(self.data[hash_value],{})
	end,
	delete = function(self, x, y, obj)
		local hash_value = self:hash(x, y)
		local hash_obj = self:hash2(obj)

		if self.data[hash_value] ~= nil then
			if self.data[hash_value][hash_obj] ~= nil then
				local obj = table.copy(self.data[hash_value][hash_obj])
				self.data[hash_value][hash_obj] = nil
				return obj
			end
		end
	end,
	exportList = function(self)
		local ret_list = {}
		for key1, tile_group in pairs(self.data) do
			for key2, tile in pairs(tile_group) do
				table.insert(ret_list, tile)
			end
		end
		return ret_list
	end,
}

local SceneLayer = Class{
	init = function(self)
		self.elements = {}	-- object, tile
	end,
}

local Scene = Class{
	init = function(self, asset_name)
		if asset_name then
			local scene = Asset.scene(asset_name)
			if scene == nil then
				error('Scene not found: \"'..tostring(asset_name)..'\"')
			else
				return scene
			end
		end

		self.layers = {}
		self.tilesets = {}
	end,

	load = function(self, scene_data)
		-- layers
		for l, layer in ipairs(scene_data.layers) do
			local new_layer = SceneLayer()

			local attributes = {'name', 'depth', 'offset', 'snap'}
			for a, attr in ipairs(attributes) do new_layer[attr] = layer[attr] end

			table.insert(self.layers, new_layer) 
		end

		-- tilesets (images)
		for i, image in ipairs(scene_data.images) do
			table.insert(self.tilesets,{
				-- image = Im
			})
		end

		return self
	end,

	resortLayers = function(self)
		self.layers = table.sort(self.layers, function(a, b) return a.depth < b.depth end)
	end
}

return Scene