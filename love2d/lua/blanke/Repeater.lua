Repeater = Class{
	init = function(self, texture, options)
		self.real_texture = nil
		self.entity_tex = false

		self.ent_time = 0
		self.ent_systems = {}
		self.system = nil

		function set(prop, ...)
			if self.system ~= nil then self.system[prop](self.system, ...) end
		end

		self.onPropSet["lifetime"] = function(self, v) set("setParticleLifetime",v) end
		self.onPropSet["duration"] = function(self, v) set("setEmitterLifetime",v) end
		self.onPropSet["rate"] = function(self, v) set("setEmissionRate",v) end
		self.onPropSet["linear_accel_x"] = function(self, v) set("setLinearAcceleration",v,self.linear_accel_y) end
		self.onPropSet["linear_accel_y"] = function(self, v) set("setLinearAcceleration",self.linear_accel_x,v) end
		self.onPropSet["linear_damp_x"] = function(self, v) set("setLinearDamping",v,self.linear_damp_y) end
		self.onPropSet["linear_damp_y"] = function(self, v) set("setLinearDamping",self.linear_damp_x,v) end
		self.onPropSet["spawn_x"] = function(self, v) set("setPosition",v,self.spawn_y) end
		self.onPropSet["spawn_y"] = function(self, v) set("setPosition",self.spawn_x,v) end


		local default_props = {"linear_accel_x","linear_accel_y","linear_damp_x","linear_damp_y","spawn_x","spawn_y"}
		for p, prop in ipairs(default_props) do
			self.onPropGet[prop] = function() return 0 end
		end
		self.onPropGet["duration"] = function() return -1 end
		self.onPropGet["lifetime"] = function() return 3 end
		self.onPropGet["rate"] = function() return 1 end

		self:setTexture(texture)

		self.x = 0
		self.y = 0

		-- self.speed = 0 -- needs max
		self.onPropSet["start_color"] = function(self, v) return Draw._parseColorArgs(v) end
		self.onPropSet["end_color"] = function(self, v) return Draw._parseColorArgs(v) end

		self.onPropGet["start_color"] = function() return {1,1,1,1} end
		self.onPropGet["end_color"] = function() return {1,1,1,1} end

		if options then
			table.update(self, options)
		end

		_addGameObject('repeater', self)
	end,

	update = function(self, dt)
		if self.entity_tex then
			self:updateEntityTexture(dt)
		else
			self.system:update(dt)
		end
	end,

	updateEntityTexture = function(self, dt)
		-- make sure spritebatches were created
		local ent_uuid = self.entity_tex.uuid
		if not self.ent_systems[ent_uuid] then
			self.ent_systems[ent_uuid] = {}
			for name, sprite in pairs(self.entity_tex._sprites) do
				if not self.ent_systems[ent_uuid][name] then
					self.ent_systems[ent_uuid][name] = {
						batch = love.graphics.newSpriteBatch(self.entity_tex._images[name].image),
						info_list = {}
					}
				else
					self.ent_systems[ent_uuid][name].batch:setTexture(self.entity_tex._images[name].image)
				end
			end
		end

		-- update positions
		if dt ~= nil then
			self.ent_time = self.ent_time + dt

			if self.ent_time > self.rate / 1000 then
				self.ent_time = 0
				-- spawn a new image
				local current_sys = self.ent_systems[self.entity_tex.uuid][self.entity_tex.sprite_index]
				local current_quad = self.entity_tex._sprites[self.entity_tex.sprite_index].frames[self.entity_tex.sprite_frame]

				if current_quad then
					local spr_info = self.entity_tex:getSpriteInfo(self.entity_tex.sprite_index)
					new_info = {
						batch_args = {current_quad,
							self.spawn_x, self.spawn_y,
							spr_info.angle,
							spr_info.xscale, spr_info.yscale, -- scale
							-spr_info.xoffset, -spr_info.yoffset, -- offset
							spr_info.xshear, spr_info.yshear -- shear
						},
						t = 0,
						max_t = self:_getVal("lifetime"),
						start_color = table.copy(self.start_color),
						color = table.copy(self.start_color),
						end_color = table.copy(self.end_color),

						accel_x = self:_getVal('linear_accel_x'),
						accel_y = self:_getVal('linear_accel_y')
					}
					local id = current_sys.batch:add(unpack(new_info.batch_args))
					table.insert(new_info.batch_args, 1, id)
					current_sys.info_list[id] = new_info
				end
			end

			-- update all images
			local systems = self.ent_systems[self.entity_tex.uuid]
			for index, sys_props in pairs(systems) do
				for id, info in pairs(sys_props.info_list) do
					local t = info.t
					info.t = t + dt

					if t > info.max_t then
						-- kill image
						systems[index].info_list[id] = nil
						sys_props.batch:set(id, 0,0,0,0,0)
					else
						-- update image

						-- COLOR
						local p = t / info.max_t
						for c = 1,4 do
							info.start_color[c] = (info.end_color[c] - info.start_color[c]) * p + info.start_color[c]
							--info.start_color[c] (1.0 - p) * info.start_color[c] + p * info.end_color[c] + 0.5
						end
						sys_props.batch:setColor(unpack(info.start_color))

						-- POSITION
						local x, y = info.batch_args[3], info.batch_args[4]

						x = x + (0.5 * info.accel_x * (t * t))
						y = y + (0.5 * info.accel_y * (t * t))

						info.batch_args[3] = x
						info.batch_args[4] = y

						sys_props.batch:set(unpack(info.batch_args))
					end
				end
			end
		end
	end,

	_getVal = function(self, name)
		if self['max_'..name] ~= nil then
			return randRange(self[name], self['max_'..name])
		end
		return self[name]
	end,

	setSpeed = function(self, min, max)
		self.system:setSpeed(min, max)
	end,

	setTexture = function(self, texture)
		self.entity_tex = false

		assert(texture, "Invalid texture '"..tostring(texture).."'")

		if texture.classname then
			if texture.classname == "Image" then self.real_texture = texture.image end
			if texture.classname == "Canvas" then self.real_texture = texture.canvas end
			if texture._entity then
				self.entity_tex = texture
				self.real_texture = 1
				self:updateEntityTexture()
			end
		end

		assert(self.real_texture, "not a valid Repeater texture")

		if self.real_texture and self.real_texture ~= 1 then
			if not self.system then
				self.system = love.graphics.newParticleSystem(self.real_texture)
			else
				self.system:setTexture(self.real_texture)
			end
			self:_refreshMutators()
		end
	end,

	draw = function(self)
		if self.entity_tex then
			-- drawing entity
			local prop_list = self.ent_systems[self.entity_tex.uuid]
			for name, props in pairs(prop_list) do
				love.graphics.draw(props.batch)
			end
		else
			local c1 = self.start_color
			local c2 = self.end_color
			self.system:setColors(c1[1], c1[2], c1[3], c1[4], c2[1], c2[2], c2[3], c2[4])

			love.graphics.draw(self.system, self.x, self.y)
		end
	end
}

return Repeater