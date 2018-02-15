-- for loading Tiled map (probably outdated)

Map = Class{
	init = function (self, map_name)
		self.name = map_name
		self.data = require(map_name)

		-- extra drawing properties
		self.color = {['r']=255,['g']=255,['b']=255}

		self._images = {}
		self._batches = {}

        self._ids = {}
        
		-- layers (tiles, images)
		self.tilesets = {} 		-- {firstgid = tileset}
		self.tilelayers = {}	-- {name = layer}
		self.objectgroups = {}	-- {name = layer}
		
		-- things that aren't just images
		self.entities = {}
		self.shapes = {}		-- collision boxes

		-- list of all layers. used for draw order.
		self._layers = {} 	

		-- load tilesets
		for t, tileset in pairs(self.data.tilesets) do
			-- resize tilesets that don't cover the entire image
			tileset.cutwidth = tileset.imagewidth - (tileset.imagewidth % tileset.tilewidth)
			tileset.cutheight = tileset.imageheight - (tileset.imageheight % tileset.tileheight)

			self.tilesets[tileset.firstgid] = tileset

			if not assets[tileset.name] then
				error("image '" .. tileset.name .. "' not found in map '" .. map_name .."'")
			end

			self._images[tileset.name] = assets[tileset.name]()
		end

		-- load tile/object layers
		for l, layer in pairs(self.data.layers) do
			local new_layer = {
				name = layer.name,
				type = layer.type
			}
			table.insert(self._layers, new_layer)

			-- TILE LAYER
			if layer.type == "tilelayer" then
				self.tilelayers[layer.name] = layer
				self._batches[layer.name] = {}

				for i_d, d in ipairs(layer.data) do
					if d > 0 then
						-- get tileset that covers this gid
						local tileset
						for gid, _tileset in pairs(self.tilesets) do
							if d >= gid then
								tileset = _tileset
							end
						end

						-- is there a spritebatch for this tileset/layer combo?
						if not self._batches[layer.name][tileset.name] then
							self._batches[layer.name][tileset.name] = love.graphics.newSpriteBatch(self._images[tileset.name])
						end

						-- get tile x/y
						local tile_x = i_d % layer.width * self.data.tilewidth - self.data.tilewidth -- offset, who knows why
						local tile_y = math.floor(i_d / layer.width) * self.data.tileheight

						-- get tile frame x/y
						local frame = d - tileset.firstgid
						local columns = tileset.cutwidth / tileset.tilewidth

						local frame_x = frame % columns * tileset.tilewidth
						local frame_y = math.floor(frame / columns) * tileset.tileheight

						-- offset for tileset smaller than grid
						local offx = 0--(tileset.tilewidth < self.data.tilewidth) and self.data.tilewidth - tileset.tilewidth or 0
						local offy = (tileset.tileheight < self.data.tileheight) and self.data.tileheight - tileset.tileheight or 0

						local quad = love.graphics.newQuad(frame_x, frame_y, tileset.tilewidth, tileset.tileheight, tileset.imagewidth, tileset.imageheight)
						local id = self._batches[layer.name][tileset.name]:add(quad, tile_x + offx, tile_y + offy, 0, 1, 1, tileset.tileoffset.y, tileset.tileoffset.x) -- yes offsetx and y are switched
					
                        -- store id
                        if self._ids[layer.name] == nil then
                            self._ids[layer.name] = {}
                        end
                        self._ids[layer.name][tile_x .. tile_y .. tileset.name] = id
                    end
				end
			end

			-- OBJECT LAYER
			if layer.type == "objectgroup" then
				self.objectgroups[layer.name] = layer

				-- ENTITIES: does not spawn the entity, just stores its data
				if layer.name == "entity" then
					for i_o, object in ipairs(layer.objects) do
						if not self.entities[object.name] then
							self.entities[object.name] = {}
						end

						table.insert(self.entities[object.name], object)
					end
				end

				-- COLLISIONS
				if layer.name == "collision" then
					for i_o, object in ipairs(layer.objects) do

						-- get hitbox id type
						local object_tag = object.tag
						
						if layer.properties.tag then
							object_tag = layer.properties.tag
						end	

						if object.shape == "rectangle" then
							self:addShape(object.name, object.shape, {object.x, object.y, object.width, object.height}, object.type, layer.offsetx, layer.offsety)
						end

						if object.shape == "ellipse" then
							self:addShape(object.name, "circle", {object.x + (self.data.tilewidth/2), object.y + (self.data.tileheight/2), object.width/2}, object.type, layer.offsetx, layer.offsety)
						end

						if object.shape == "polygon" then
							local points = {}
							for i_p, point in ipairs(object.polygon) do
								table.insert(points, point.x + object.x)
								table.insert(points, point.y + object.y)
							end

							self:addShape(object.name, "polygon", points, object_tag, layer.offsetx, layer.offsety)
						end

					end
				end
			end
		end -- for loop
        
        _addGameObject('map',self)
	end,

	--[[
	getTile = function(self, x, y)

	end,
	]]--
    
    removeTile = function(self, x, y, tileset_name, layer_name)
        local new_x = x - (x % self.data.tilewidth)
        local new_y = y - (y % self.data.tileheight)
        local tile_id = new_x .. new_y .. tileset_name
        
        -- iterate through batches
        for batch_name, batch in pairs(self._batches) do
            if layer_name == nil or layer_name == batch_name then
                -- iterate through id layers
                for id_name, id_keys in pairs(self._ids) do
                    if layer_name == nil or layer_name == id_name then
                        
                        if batch[tileset_name] and self._ids[id_name][tile_id] then
                            batch[tileset_name]:set(self._ids[id_name][tile_id], 0, 0, 0, 0, 0)
                        end
                        
                    end
                end
            end
        end
    end,

	-- add a collision shape
	-- str shape: rectangle, polygon, circle, point
	-- str name: reference name of shape
	addShape = function(self, name, shape, args, tag, xoffset, yoffset)
		local new_shape
		-- args {x, y, width, height}
		if shape == "rectangle" then
			args[1] = args[1] + xoffset
			args[2] = args[2] + yoffset
			new_shape = HC.rectangle(unpack(args))

		-- args {x1, y1, x2, y2, ...}
		elseif shape == "polygon" then
			for a = 1, #args, 2 do
				args[a] = args[a] + xoffset
				args[a+1] = args[a+1] + yoffset
			end
			new_shape = HC.polygon(unpack(args))

		-- args {x, y, radius}
		elseif shape == "circle" then
			args[1] = args[1] + xoffset
			args[2] = args[2] + yoffset
			new_shape = HC.circle(unpack(args))
		end

		new_shape.xoffset = args[1] - xoffset
		new_shape.yoffset = args[2] - yoffset
		new_shape.name = name
		new_shape.tag = tag
		table.insert(self.shapes, new_shape)

		HC.register(new_shape)
	end,

	getEntity = function (self, name) 
		-- only type is given
		if self.entities[name] and #self.entities[name] == 1 then
			return self.entities[name][1]
		end

		return self.entities[name]

		--[[ return entity with certain type & name (deprecated)
		for i_e, entity in ipairs(self.entities[name]) do
			if entity.name == name then
				return entity
			end
		end]]--
	end,

	update = function (self, dt)

	end,

	debugCollision = function(self)
		-- draw collision shapes
		for s, shape in pairs(self.shapes) do
			shape:draw("line")
		end
	end,

	draw = function (self)
		for i_l, _layer in ipairs(self._layers) do
			-- TILELAYER
			if _layer.type == "tilelayer" then
				local layer = self.tilelayers[_layer.name]
				local layer_batches = self._batches[_layer.name]

				for tileset_name, batch in pairs(layer_batches) do
					if layer.visible then
						love.graphics.push()

						love.graphics.translate(layer.offsetx, layer.offsety)
						love.graphics.setColor(self.color.r, self.color.g, self.color.b, layer.opacity*255)

						love.graphics.draw(batch, 0, 0)
						love.graphics.pop()
					end
				end
			end
		end
	end,
}

return Map