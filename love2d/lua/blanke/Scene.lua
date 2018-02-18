local _btn_place
local _btn_remove
local _btn_confirm
local _btn_no_snap
local _btn_zoom_in

local _last_place = {nil,nil}
local _place_type
local _place_obj
local _place_layer

local layer_template = {entity={},tile={},hitbox={}}

-- hitbox placing
local hitbox_points = {}
local hitbox_rem_point = true

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

Scene = Class{
	hitbox = {},
	_zoom_amt = 1,
	_fake_view_start = {CONF.window.width/2, CONF.window.height/2},
	_renames = {},
	_fake_view = nil,
	init = function(self, name)
		self.layer_data = {}			-- load_objct
		self.layer_order = {}			-- layers
		self.layer_settings = {}		-- grid snap and tile snap
		self.images = {}
		self.name = name
		self._snap = {32,32}
		self._delete_similar = true
		self._is_active = 2

		self.hash_tile = Scenetable()

		if BlankE._ide_mode then
			_btn_place = Input('mouse.1')
			_btn_remove = Input('mouse.2')
			_btn_confirm = Input('return','kpenter')
			_btn_no_snap = Input('lctrl','rctrl')
			_btn_zoom_in = Input('wheel.up')
			_btn_zoom_out = Input('wheel.down')		
		end

		local load_scene = Asset.file(name)
		if load_scene then
			self:load(load_scene, Asset.getInfo('file', name))
		end

		if #self.layer_order == 0 then
			self:addLayer()
		end

		Scene._fake_view.drag_offset_x = Scene._fake_view_start[1]
		Scene._fake_view.drag_offset_y = Scene._fake_view_start[2]
		Scene._fake_view._is_a_fake = true

		self.draw_hitboxes = false
		self.show_debug = false
		self.classname = name
		_addGameObject('scene',self)
	end,

	-- returns json
	export = function(self, path)
		local output = {order=self.layer_order,data={},settings=self.layer_settings}

		-- iterate LAYERS
		for l, layer in ipairs(self.layer_order) do
			local data = self.layer_data[layer]
			output.data[layer] = {}

			-- iterate OBJECT TYPES
			for obj_type, objects in pairs(data) do
				local out_layer = {}

				-- iterate OBJECTS
				for o, obj in ipairs(objects) do
					if obj._loadedFromFile and not obj._destroyed then
						if obj_type == 'entity' then
							-- if entity was renamed, replace it here
							local classname = obj.classname
							if Scene._renames[classname] then
								classname = Scene._renames[classname]
							end

							local ent_data = {
								classname=classname,
								x=obj.xstart,
								y=obj.ystart
							}
							table.insert(out_layer, ent_data)
						end

						if obj_type == 'hitbox' then
							local hit_data = {
								name=obj:getTag(),
								points=obj.args
							}
							table.insert(out_layer, hit_data)
						end
					end
				end
				output.data[layer][obj_type] = out_layer
			end
		end

		-- save tiles
		local tiles = self.hash_tile:exportList()

		for t, tile in pairs(tiles) do
			output.data[tile.layer] = ifndef(output.data[tile.layer],{})
			output.data[tile.layer]['tile'] = ifndef(output.data[tile.layer]['tile'],{})
			local img_data = {
				x=tile.x,
				y=tile.y,
				img_name=tile.img_name,
				crop=tile.crop,
			}
			table.insert(output.data[tile.layer].tile, img_data)
		end

		-- save hitboxes
		output.data['hitbox'] = Scene.hitbox
		--output.objects['layers'] = self.load_objects.layers

		return json.encode(output)
	end,

	load = function(self, scene_string, format)
		scene_data = json.decode(scene_string)


		self.layer_data = {}
		self.layer_order = scene_data.order
		self.layer_settings = scene_data.settings
		Scene.hitbox = ifndef(scene_data.data.hitbox, {})

		-- iterate LAYERS
		local types = {'tile','hitbox','entity'} -- uses list to make load order same every time
		for layer, data in pairs(scene_data.data) do
			if not _place_layer then
				self:setPlaceLayer(layer)
			end
			self.layer_data[layer] = table.copy(layer_template)

			for t, obj_type in ipairs(types) do
				if obj_type == 'entity' and data["entity"] then
					for i_e, entity in ipairs(data["entity"]) do
						if _G[entity.classname] then
							Entity.x = entity.x
							Entity.y = entity.y
							local new_entity = _G[entity.classname](self)
							new_entity._loadedFromFile = true

							self:addEntity(new_entity, layer)
						end
					end
				end

				if obj_type == 'tile' and data["tile"] then
					for i_i, tile in ipairs(data["tile"]) do
						self:addTile(tile.img_name, tile.x, tile.y, tile.crop, layer, true)
					end
				end

				if obj_type == 'hitbox' and data["hitbox"] then
					for i_h, hitbox in ipairs(data["hitbox"]) do
						local new_hitbox = self:addHitbox(hitbox.name, {points=hitbox.points}, layer)
						new_hitbox._loadedFromFile = true
					end
				end
			end
		end   
		
		return self
	end,

	_checkLayerArg = function(self, layer)
		if layer == nil then
			return self:_checkLayerArg(0)
		end
		if type(layer) == "number" then
			layer = "layer"..tostring(layer)
			self.layer_data[layer] = ifndef(self.layer_data[layer],table.copy(layer_template))
		end

		return layer
	end,

	getList = function(self, obj_type) 
		local obj_list = {}
		if obj_type == 'layer' then
			return ifndef(self.layer_order,{})
		elseif obj_type == 'hitbox' then
			return Scene.hitbox
		else
			for layer, data in pairs(self.layer_data) do
				obj_list[layer] = data[obj_type]
			end
		end
		return obj_list
	end,

	addLayer = function(self)
		local layer_list = self.layer_order
		local layer_num = #layer_list
		local valid_name = false
		local layer_name = 'layer'..layer_num

		while not valid_name do
			valid_name = true
			for l, layer in ipairs(layer_list) do
				if layer == layer_name then
					valid_name = false
					layer_num = layer_num + 1
					layer_name = 'layer'..layer_num
				end
			end
		end

		table.insert(self.layer_order, layer_name)
		self.layer_data[layer_name] = table.copy(layer_template)
		self:setPlaceLayer(layer_name)
	end,

	removeLayer = function(self)
		local layer_index = table.find(self.layer_order, _place_layer)
		local layer_name = self.layers[layer_index]
		self.layer_data[layer_name] = nil
		table.remove(self.layer_order, layer_index)
	end,

	getPlaceLayer = function(self)
		return _place_layer
	end,

	setPlaceLayer = function(self, layer_num)
		_place_layer = self:_checkLayerArg(layer_num)
	end,

	moveLayerUp = function(self)
		-- get position of current layer
		local curr_layer_pos = 1
		for l, layer in ipairs(self.layer_order) do
			if layer == _place_layer then
				curr_layer_pos = l
			end
		end

		-- able to move the layer up anymore?
		if curr_layer_pos > 1 then
			-- switch their contents
			local prev_layer = self.layer_order[curr_layer_pos-1]
			local curr_layer = self.layer_order[curr_layer_pos]
			self.layer_order[curr_layer_pos] = prev_layer
			self.layer_order[curr_layer_pos-1] = curr_layer
		end
	end,

	moveLayerDown = function(self)
		-- get position of current layer
		local curr_layer_pos = 1
		for l, layer in ipairs(self.layer_order) do
			if layer == _place_layer then
				curr_layer_pos = l
			end
		end

		-- able to move the layer up anymore?
		if curr_layer_pos < #self.layer_order then
			-- switch their contents
			local prev_layer = self.layer_order[curr_layer_pos+1]
			local curr_layer = self.layer_order[curr_layer_pos]
			self.layer_order[curr_layer_pos] = prev_layer
			self.layer_order[curr_layer_pos+1] = curr_layer
		end
	end,

	addEntity = function(self, ...)
		local args = {...}
		local ret_ent
		if type(args[1]) == "string" then
			ret_ent = self:_addEntityStr(unpack(args))
		end
		if type(args[1]) == "table" then
			ret_ent = self:_addEntityTable(unpack(args))
		end
		if ret_ent then
			ret_ent:update(0)
		end
		return ret_ent
	end,

	_addEntityTable = function(self, entity, layer) 
		layer = self:_checkLayerArg(layer)

		self.layer_data[layer]["entity"] = ifndef(self.layer_data[layer]["entity"], {})
		table.insert(self.layer_data[layer].entity, entity)
	end,

	_addEntityStr = function(self, ent_name, x, y, layer, width, height)
		Entity.x = x
		Entity.y = y
		local new_entity = _G[ent_name](self)
		self:_addEntityTable(new_entity, layer)

		return new_entity
	end,

	addTile = function(self, img_name, x, y, img_info, layer, from_file) 
		layer = self:_checkLayerArg(layer)

		--if Image.exists(img_name) then
			-- check if the spritebatch exists yet
			self.layer_data[layer]["tile"] = ifndef(self.layer_data[layer]["tile"], {})
			self.images[img_name] = ifndef(self.images[img_name], Image(img_name))
			self.layer_data[layer].tile[img_name] = ifndef(self.layer_data[layer].tile[img_name], love.graphics.newSpriteBatch(self.images[img_name]()))

			-- add tile to batch
			local spritebatch = self.layer_data[layer].tile[img_name]
			local sb_id = spritebatch:add(love.graphics.newQuad(img_info.x, img_info.y, img_info.width, img_info.height, self.images[img_name].width, self.images[img_name].height), x, y)

			-- add tile info to "hashtable"
			self.hash_tile:add(x-(x%self._snap[1]),y-(y%self._snap[2]),
			{
				layer=layer,
				x=x,
				y=y,
				img_name=img_name,
				crop=img_info,
				id=sb_id,
				from_file=from_file
			})
		--end
		return self
	end,

	-- returns list of tile_data
	getTile = function(self, x, y, layer, img_name)
		x = x-(x%self._snap[1])
		y = y-(y%self._snap[2])
		if layer ~= nil then
			layer = self:_checkLayerArg(layer)
		end
		local ret_tiles = {}

		local tiles = self.hash_tile:search(x, y)
		for hash, tile in pairs(tiles) do
			local can_return = true

			if tile.layer ~= layer then
				can_return = false
			end
			if layer == nil then
				can_return = true
			end
			if img_name and self._delete_similar and tile.img_name ~= img_name then
				can_return = false
			end

			if can_return then
				table.insert(ret_tiles, tile)
			end
		end

		return ret_tiles
	end,

	-- same as getTile but returns list of Image()
	getTileImage = function(self, x, y, layer, img_name)
		local ret_tiles = self:getTile(x,y,layer,img_name)
		for t, tile in ipairs(ret_tiles) do
			ret_tiles[t] = self:tileToImage(tile)
		end
		
		if table.len(ret_tiles) == 1 then
			return ret_tiles[1]
		end
		return ret_tiles
	end,

	tileToImage = function(self, tile_data)
		local img = self.images[tile_data.img_name]
		return img:crop(tile_data.crop.x, tile_data.crop.y, tile_data.crop.width, tile_data.crop.height)
	end,

	removeTile = function(self, x, y, layer_name, img_name, permanent)
		local rm_tiles = self:getTile(x,y,layer_name,img_name)

		-- remove them from spritebatches
		for layer, data in pairs(self.layer_data) do
			if layer_name == nil or layer_name == layer then
				for t, tile in ipairs(ifndef(rm_tiles, {})) do
					if permanent then self.hash_tile:delete(x, y, tile) end
					if data.tile then
						data.tile[tile.img_name]:set(tile.id, 0, 0, 0, 0, 0)
					end
				end
			end
		end
		return self
	end,

	getHitboxType = function(self, name)
		for h, hitbox in pairs(Scene.hitbox) do
			if hitbox.name == name then
				return hitbox
			end
		end
	end,

	addBlankHitboxType = function(self)
		local new_name = self:validateHitboxName('hitbox'..tostring(#Scene.hitbox))

		self:setHitboxInfo(new_name,{
			color={255,255,255,255},
			uuid=uuid()
		})
		return self
	end,

	validateHitboxName = function(self, new_name)
		local count = 1
		while self:getHitboxType(new_name) ~= nil do
			new_name = new_name..tostring(count)
			count = count + 1
		end
		return new_name
	end,

	renameHitbox = function(self, old_name, new_name)
		for layer, data in pairs(self.layer_data) do 
			if data.hitbox then
				for h, hitbox in ipairs(data.hitbox) do
					if hitbox.HCShape.tag == old_name then
						hitbox.HCShape.tag = new_name
					end
				end
			end
		end

		for h, hitbox in pairs(Scene.hitbox) do
			if hitbox.name == old_name then
				hitbox.name = self:validateHitboxName(new_name)
				return hitbox
			end
		end
	end,
	--[[
	recolorHitbox = function(self, name, color)
		Hitbox.
	end,]]

	setHitboxInfo = function(self, name, info)
		local found = false
		for h, hitbox in pairs(Scene.hitbox) do
			if hitbox.name == name then
				hitbox = info
				found = true
			end
		end

		if not found then
			info.name = name
			table.insert(Scene.hitbox, info)
		end
	end,

	addHitbox = function(self, hit_name, hit_info, layer) 
		layer = self:_checkLayerArg(layer)

		-- hitboxes are accessable to all scenes
		local hitbox_info = self:getHitboxType(hit_name)
		if not hitbox_info then
			self:setHitboxInfo(hit_name,{
				name=hit_name,
				color=hit_info.color,
				uuid=uuid()
			})
			hitbox_info = self:getHitboxType(hit_name)
		end

		self.layer_data[layer]["hitbox"] = ifndef(self.layer_data[layer]["hitbox"], {})
		local new_hitbox = Hitbox("polygon", hit_info.points, hit_name)
		new_hitbox:setColor(hitbox_info.color)
		new_hitbox.hitbox_uuid = hit_info.uuid
		new_hitbox.parent = self
		table.insert(self.layer_data[layer].hitbox, new_hitbox)

		return new_hitbox
	end,

	removeHitboxAtPoint = function(self, x, y, in_layer)
		in_layer = self:_checkLayerArg(in_layer)

	    for layer, data in pairs(self.layer_data) do
	    	if data.hitbox then
		    	for h, hitbox in ipairs(data.hitbox) do
					if layer == in_layer and hitbox:pointTest(x, y) then
						hitbox:destroy()
						table.remove(self.layer_data[layer].hitbox, h)
					end
				end
			end
		end
	end,

	getEntity = function(self, in_entity, in_layer)
		local entities = {}
		for layer, data in pairs(self.layer_data) do
			if in_layer == nil or in_layer == layer then
				for i_e, entity in ipairs(ifndef(data.entity,{})) do
					if entity.classname == in_entity then
						table.insert(entities, entity)
					end
				end
			end
		end

		if #entities == 1 then
			return entities[1]
		end
			return entities
	end,

	_getMouseXY = function(self, dont_snap)
		dont_snap = ifndef(dont_snap, _btn_no_snap())

		local cam_x, cam_y = BlankE._mouse_x, BlankE._mouse_y
		--cam_x = cam_x - (place_cam.port_width/2)
		--cam_y = cam_y - (place_cam.port_height/2)
		local mx, my = cam_x*Scene._zoom_amt, cam_y*Scene._zoom_amt

		if not dont_snap then
			mx = mx-(mx%self._snap[1])
			my = my-(my%self._snap[2])
		end

		return {mx, my}
	end,

	setSetting = function(self, prop, value) 
		-- store settting
		local layer = self:getPlaceLayer()
		self.layer_settings[layer] = ifndef(self.layer_settings[layer], {})
		self.layer_settings[layer][prop] = value
	end,

	getSetting = function(self, prop, default_val)
		local layer = self:getPlaceLayer()
		-- set default value
		if not self.layer_settings[layer] or not self.layer_settings[layer][prop] then
			self:setSetting(prop, default_val)
		end
		return self.layer_settings[layer][prop]
	end,

	update = function(self, dt)
		if not BlankE.pause then 
			-- update entities
			for layer, data in pairs(self.layer_data) do
				if data.entity then
					for i_e, entity in ipairs(data.entity) do
						if entity._destroyed then
							table.remove(data.entity, i_e)
						else
							entity:update(dt)
						end
					end
				end

				if data.hitbox then
					--for i_h, hitbox in ipairs(data.hitbox) do
						-- nothing at the moment
					--end
				end
			end
		end

		if BlankE._ide_mode then
			-- reset hitbox vars
	    	if _place_type ~= 'hitbox' or (_place_type == 'hitbox' and not _place_obj) then
				hitbox_points = {}
				hitbox_rem_point = true
	    	end

	    	-- placing object on click
	    	local _placeXY = self:_getMouseXY()
	    	BlankE._snap_mouse_x, BlankE._snap_mouse_y = unpack(_placeXY)
	    	if _btn_place() and _place_type then
	    		if _placeXY[1] ~= _last_place[1] or _placeXY[2] ~= _last_place[2] then
	    			_last_place = _placeXY

	    			if _place_type == 'entity' then
	    				local new_entity = self:addEntity(_place_obj, _placeXY[1], _placeXY[2], _place_layer)
	    				if new_entity then
	    					new_entity._loadedFromFile = true
	    				end
	    			end
	    			
	    			if _place_type == 'image' then
	    				local new_tile = self:addTile(_place_obj.img_name, _placeXY[1], _placeXY[2], _place_obj, _place_layer, true)
	    			end

	    			if _place_type == 'hitbox' then
	    				table.insert(hitbox_points, _placeXY[1])
	    				table.insert(hitbox_points, _placeXY[2])
	    			end
	    		end
	    	end

	    	-- removing objects on click
	    	if _btn_remove() and _place_type then
				_last_place = {nil,nil}
	    		if _place_type == 'image' then
	    			self:removeTile(_placeXY[1], _placeXY[2], _place_layer, _place_obj.img_name, true)
	    		end

	    		if _place_type == 'hitbox' then
	    			if #hitbox_points > 0 and hitbox_rem_point then
		    			table.remove(hitbox_points, #hitbox_points)
		    			table.remove(hitbox_points, #hitbox_points)
		    			hitbox_rem_point = false
		    		elseif #hitbox_points == 0 and hitbox_rem_point then -- added 'hitbox_rem_point' and it just happened to work here
		    			local new_mx, new_my = unpack(self:_getMouseXY(true))
					    self:removeHitboxAtPoint(new_mx, new_my)
		    		end
	    		end
	    	else
	    		if _place_type == 'hitbox' then
	    			hitbox_rem_point = true
	    		end
	    	end

		    -- confirm button
		    if _btn_confirm() and not confirm_pressed then
		    	confirm_pressed = true

		    	if _place_type == 'hitbox' then
		    		if #hitbox_points >= 6 then
		    			-- make sure it's not a straight line
		    			local invalid = true
		    			local slope = 0

		    			for h=1,#hitbox_points-2,2 do
		    				local h1 = {hitbox_points[h], hitbox_points[h+1]}
		    				local h2 = {hitbox_points[h+2], hitbox_points[h+3]}

		    				local new_slope = (h2[2]-h1[2])/(h2[1]-h1[1])
		    				
		    				if slope ~= new_slope then
		    					slope = new_slope
		    					invalid = false
		    				end
		    			end

		    			if not invalid then
		    				local new_hitbox = self:addHitbox(_place_obj.name, {points=hitbox_points})
		    				new_hitbox._loadedFromFile = true
		    				hitbox_points = {}
		    				hitbox_rem_point = true
		    			end
		    		end
		    	end

		    elseif confirm_pressed then
		    	confirm_pressed = false
		    end

		    -- only use fake view if no other view is being used
	    	local total = 0
	    	_iterateGameGroup('view', function(view)
	    		if view._is_drawing > 0 and not view._is_a_fake then
		    		total = total + 1
		    	end
	    	end)
	    	if total > 0 then
		    	Scene._fake_view.disabled = true
		    else
		    	Scene._fake_view.disabled = false
		    end
		end
	end,

	_real_draw = function(self)
		self._is_active = 2

		for l, layer in ipairs(self.layer_order) do
			local data = self.layer_data[layer]

			if BlankE._ide_mode and _place_layer ~= layer then
				love.graphics.push('all')
				love.graphics.setColor(255,255,255,255/2.5)
			end

			if data.entity then
				for i_e, entity in ipairs(data.entity) do
					entity.scene_show_debug = self.show_debug
					entity:draw()
				end
			end

			if data.tile then
				for name, tile in pairs(data.tile) do
					love.graphics.draw(tile)
				end
			end

			if BlankE._ide_mode and _place_layer ~= layer then
				love.graphics.pop()
			end

			if data.hitbox and (self.draw_hitboxes or self.show_debug) and not BlankE._ide_mode then
				for i_h, hitbox in ipairs(data.hitbox) do
					hitbox:draw()
				end
			end
		end
	end,

	draw = function(self) 
	    if BlankE._ide_mode then
	    	-- zooming in and out
	    	if _btn_zoom_in() then
	    		Scene._zoom_amt = clamp(Scene._zoom_amt - 0.1, 0, 3)
	    	end

	    	if _btn_zoom_out() then
	    		Scene._zoom_amt = clamp(Scene._zoom_amt + 0.1, 0, 3)
	    	end
	    	
	    	-- dragging the view/grid around
	    	BlankE.setGridSnap(self._snap[1], self._snap[2])

	    	Scene._fake_view:attach()
	    	
	    	self:_real_draw()

	    	-- draw hitbox being placed
	    	if _place_type == 'hitbox' and _place_obj and #hitbox_points > 0 then
		    	love.graphics.push('all')
		    	local color_copy = table.copy(_place_obj.color)
	    		color_copy[4] = 255
		    	for h=1,#hitbox_points,2 do
		    		love.graphics.setColor(unpack(color_copy))
		    		love.graphics.circle('fill', hitbox_points[h], hitbox_points[h+1], 2)
		    		love.graphics.setColor(0,0,0,255/2)
		    		love.graphics.circle('line', hitbox_points[h], hitbox_points[h+1], 3)
		    	end
	    		color_copy[4] = 255/2
	    		love.graphics.setColor(unpack(color_copy))
	    		if #hitbox_points == 4 then
	    			love.graphics.line(unpack(hitbox_points))
	    		elseif #hitbox_points > 4 then
	    			love.graphics.polygon('fill', unpack(hitbox_points))
	    		end
		    	love.graphics.pop()
		    end

		    -- draw hitboxes
		    for layer, data in pairs(self.layer_data) do
		    	if data.hitbox then
			    	for h, hitbox in ipairs(data.hitbox) do
			    		hitbox:draw()
			    	end
			    end
		    end

	    	Scene._fake_view:detach()
	    else
	    	self:_real_draw()
	    end
	end,

	focusEntity = function(self, ent)
		if Scene._fake_view then
			-- removing followed entity
			if ent == nil and Scene._fake_view.follow_entity then
				Scene._fake_view.follow_entity.show_debug = false
				Scene._fake_view.offset_x = 0
				Scene._fake_view.offset_y = 0
			end
			-- following entity
			if ent then
				-- TODO: offset not working as intended
				Scene._fake_view.offset_x = Scene._fake_view.port_width - game_width 
				Scene._fake_view.offset_y = Scene._fake_view.port_height - game_height
				ent.show_debug = true
			end

			Scene._fake_view:follow(ent)
		end
	end,

	setPlacer = function(self, type, obj)
		_place_type = type
		_place_obj = obj
	end,
}

return Scene