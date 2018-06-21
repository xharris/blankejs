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
		self.parent = nil
		self.images = {}
		self.hashtable = Scenetable()
		self.spritebatches = {}
		self.hitboxes = {}
	end,

	addTile = function(self, img_name, rect)
		local img_ref = self.parent.tilesets[img_name]
		if img_ref then
			self.images[img_name] = Image(img_name)

			local tile_info = {
				x=rect[1], y=rect[2],
				crop={x=rect[3], y=rect[4], w=rect[5], h=rect[6]},
				name=img_name
			}

			-- add to spritebatch
			self.spritebatches[img_name] = ifndef(self.spritebatches[img_name], love.graphics.newSpriteBatch(self.images[img_name]()))
			tile_info.id = self.spritebatches[img_name]:add(love.graphics.newQuad(tile_info.crop.x, tile_info.crop.y, tile_info.crop.w, tile_info.crop.h, self.images[img_name].width, self.images[img_name].height), tile_info.x, tile_info.y)

			-- add to tile hashtable
			self.hashtable:add(tile_info.x, tile_info.y, tile_info)
		end
	end,

	addHitbox = function(self, points, tag)
		self.hitboxes[tag] = ifndef(self.hitboxes[tag], {})
		local new_hitbox = Hitbox("polygon", {100,100, 200,100, 200,200, 100,200}, tag)
		print_r(new_hitbox)
		new_hitbox.color = Draw.green
		table.insert(self.hitboxes[tag], new_hitbox)
	end,

	draw = function(self)
		for b, batch in ipairs(self.spritebatches) do
			love.graphics.draw(batch)
		end

		for name, hitboxes in pairs(self.hitboxes) do
			for h, hitbox in ipairs(hitboxes) do
				print(hitbox:bbox())
				hitbox:draw('fill')
			end
		end
	end
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
		self.objects = {}
	end,

	getLayer = function(self, name)
		for l, layer in ipairs(self.layers) do
			if layer.name == name then return layer end
		end
	end,

	load = function(self, scene_data)
		-- layers
		for l, layer in ipairs(scene_data.layers) do
			local new_layer = SceneLayer()
			new_layer.parent = self

			local attributes = {'name', 'depth', 'offset', 'snap'}
			for a, attr in ipairs(attributes) do new_layer[attr] = layer[attr] end

			table.insert(self.layers, new_layer) 
		end
		self:sortLayers()

		-- tilesets (images)
		for i, image in ipairs(scene_data.images) do
			local img_name = Asset.getNameFromPath('image', cleanPath(image.path))
			self.tilesets[img_name] = {
				image = Image(img_name),
				snap = image.snap,
				offset = image.offset,
				spacing = image.spacing
			}
			
			-- add placed tile data
			for layer_name, coords in pairs(image.coords) do
				for c, coord in ipairs(coords) do
					local layer = self:getLayer(layer_name)
					layer:addTile(img_name, coord)
				end
			end
		end

		-- objects (just store their info)
		for o, object in ipairs(scene_data.objects) do
			self.objects[object.name] = ifndef(self.objects[object.name], {})
			local attributes = {'char', 'color', 'polygons'}
			for a, attr in ipairs(attributes) do self.objects[object.name][attr] = object[attr] end
		end

		return self
	end,

	sortLayers = function(self)
		table.sort(self.layers, function(a, b) return a.depth < b.depth end)
	end,

	draw = function(self, layer_name)
		for l, layer in ipairs(self.layers) do
			if layer_name == nil or layer.name == layer_name then 
				layer:draw()
			end
		end
	end,

	getObjects = function(self, name)
		if self.objects[name] then
			return self.objects[name].polygons
		end
		return {}
	end,

	getObjectInfo = function(self, name)
		if self.objects[name] then
			return self.objects[name]
		end
	end,

	addHitbox = function(self, ...)
		local obj_names = {...}

		for n, name in ipairs(obj_names) do
			if self.objects[name] then
				for layer_name, polygons in pairs(self.objects[name].polygons) do
					local layer = self:getLayer(layer_name)
					for p, polygon in ipairs(polygons) do
						layer:addHitbox(polygon, name)
					end
				end
			end
		end
	end,
}

return Scene