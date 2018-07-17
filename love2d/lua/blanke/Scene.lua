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
	exportList = function(self, key, val)
		local ret_list = {}
		for key1, tile_group in pairs(self.data) do
			for key2, tile in pairs(tile_group) do
				if not key or (key and tile[key] == val) then
					table.insert(ret_list, tile)
				end
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
		self.entities = {}
		
		self.offx = 0
		self.offy = 0

		self.draw_hitboxes = false
	end,

	-- {image (path/name), x, y, crop {x,y,w,h}}
	addTile = function(self, info)
		local img_name = info.image

		local img_ref = self.parent.tilesets[img_name]
		if img_ref then
			self.images[img_name] = Image(img_name)

			local tile_info = info

			-- add to spritebatch
			self.spritebatches[img_name] = ifndef(self.spritebatches[img_name], love.graphics.newSpriteBatch(self.images[img_name]()))
			info.id = self.spritebatches[img_name]:add(love.graphics.newQuad(info.crop.x, info.crop.y, info.crop.w, info.crop.h, self.images[img_name].width, self.images[img_name].height), info.x, info.y)

			-- add to tile hashtable
			self.hashtable:add(info.x, info.y, info)
		end
	end,

	addHitbox = function(self, points, tag, color)
		self.hitboxes[tag] = ifndef(self.hitboxes[tag], {})
		local new_hitbox = Hitbox("polygon", points, tag)
		new_hitbox:setColor(color)
		table.insert(self.hitboxes[tag], new_hitbox)
	end,

	addEntity = function(self, instance)
		table.insert(self.entities, instance)
	end,

	getTiles = function(self, name)
		if name then
			return self.hashtable:exportList('image', name)
		end
		return self.hashtable:exportList()
	end,

	translate = function(self, x, y)
		x, y = ifndef(x,0), ifndef(y,0)
		self.offx = self.offx + x
		self.offy = self.offy + y
		for name, hitboxes in pairs(self.hitboxes) do
			for h, hitbox in ipairs(hitboxes) do
				hitbox:move(x, y)
			end
		end
	end,

	draw = function(self)
		Draw.stack(function()
			Draw.translate(self.offx, self.offy)
			for image, batch in pairs(self.spritebatches) do
				love.graphics.draw(batch)
			end
			--[[
			for e, entity in ipairs(self.entities) do
				entity:draw()
			end
			]]
		end)

		--if self.draw_hitboxes then
			for name, hitboxes in pairs(self.hitboxes) do
				for h, hitbox in ipairs(hitboxes) do
					hitbox:draw('fill')
				end
			end
		--end
	end
}

local Scene = Class{
	init = function(self, asset_name)
		self.layers = {}
		self.tilesets = {}
		self.objects = {}
        
		if asset_name then
			local scene = Asset.scene(asset_name)
			assert(scene, 'Scene not found: \"'..tostring(asset_name)..'\"')
			self:load(scene)
		end

		_addGameObject('scene', self)
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
			local img_obj = Image(image.path)
			local img_name = Asset.getNameFromPath('image', image.path)

			self.tilesets[img_name] = {
				image = Image(img_name),
				snap = image.snap,
				offset = image.offset,
				spacing = image.spacing
			}
			
			-- add placed tile data
			for layer_name, coords in pairs(image.coords) do
				for c, coord in ipairs(coords) do
					self:addTile(layer_name, {
						x=coord[1], y=coord[2],
						crop={x=coord[3], y=coord[4], w=coord[5], h=coord[6]},
						image=img_name
					})
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
		return self
	end,

	draw = function(self, layer_name)
		for l, layer in ipairs(self.layers) do
			if layer_name == nil or layer.name == layer_name then 
				layer:draw()
			end
		end
	end,

	translate = function(self, x, y)
		for l, layer in ipairs(self.layers) do
			layer:translate(x, y)
		end
		return self
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

	-- info = {x, y, rect{}, image}
	addTile = function(self, layer_name, info)
		local layer = self:getLayer(layer_name)
		layer:addTile(info)
		return self
	end,

	-- {{x, y, image (img_name), crop{x, y, w, h} }}
	getTiles = function(self, layer_name, img_name)
		local layer = self:getLayer(layer_name)
		return layer:getTiles(img_name)
	end,

	addHitbox = function(self, ...)
		local obj_names = {...}

		for n, name in ipairs(obj_names) do
			local object = self:getObjectInfo(name)
			if object then
				for layer_name, polygons in pairs(object.polygons) do
					local layer = self:getLayer(layer_name)
					for p, polygon in ipairs(polygons) do
						layer:addHitbox(polygon, name, object.color)
					end
				end
			end
		end
		return self
	end,

	-- returns table of created entities
	addEntity = function(self, obj_name, ent_class, align) 
		local instances = {}
		local object = self:getObjectInfo(obj_name)
		if object then
			for layer_name, polygons in pairs(object.polygons) do
				local layer = self:getLayer(layer_name)
				for p, polygon in ipairs(polygons) do
					local new_entity
					if ent_class.classname then 	-- arg is an already made entity
						new_entity = ent_class
					else							-- arg is a class that needs to be instantiated
						new_entity = ent_class()
					end
					new_entity.x = polygon[1]
					new_entity.y = polygon[2]

					if align then
						if align:contains("center") then
							new_entity.x = polygon[1] - new_entity.sprite_width/2
							new_entity.y = polygon[2] - new_entity.sprite_height/2
						end
						if align:contains("top") then
							new_entity.y = polygon[2] - layer.snap[2]/2
						end
						if align:contains("bottom") then
							new_entity.y = polygon[2] + layer.snap[2]/2 - new_entity.sprite_height
						end
						if align:contains("left") then
							new_entity.x = polygon[1] - layer.snap[1]/2
						end
						if align:contains("right") then
							new_entity.x = polygon[1] + layer.snap[1]/2 - new_entity.sprite_width
						end
					end

					layer:addEntity(new_entity)
					table.insert(instances, new_entity)
				end
			end
		end
		return instances
	end
}

return Scene