Repeater = Class{
	init = function(self, texture, options)
		self.real_texture = nil
		self.entity_tex = false

		self.ent_time = 0
		self.ent_systems = {}
		self.system = nil

		self:setTexture(texture)
	
		self.x = 0
		self.y = 0
		self.duration = -1
		self.lifetime = 5 -- needs max
		self.rate = 1
		self.linear_accel_x = 0 -- needs max
		self.linear_accel_y = 0
		self.linear_damp_x = 0
		self.linear_damp_y = 0
		self.spawn_x = 0
		self.spawn_y = 0
		-- self.speed = 0 -- needs max
		self.color = {1,1,1,1}
		self.end_color = {1,1,1,1}


		if options then
			table.update(self, options)
		end

		self.color = Draw._parseColorArgs(self.color)
		self.end_color = Draw._parseColorArgs(self.end_color)

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
						start_color = table.copy(self.color),
						color = table.copy(self.color),
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
					info.t = info.t + dt

					local t = info.t
					if t > info.max_t then
						-- kill image
						systems[index].info_list[id] = nil
						sys_props.batch:set(id, 0,0,0,0,0)
					else
						-- update image

						-- COLOR
						local p = t / info.max_t
						for c = 1,4 do
							info.color[c] = (info.end_color[c] - info.start_color[c]) * p + info.start_color[c]
							--info.color[c] (1.0 - p) * info.start_color[c] + p * info.end_color[c] + 0.5
						end
						sys_props.batch:setColor(unpack(info.color))

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
			-- drawing normal particle system
			self.system:setParticleLifetime(self.lifetime)
			self.system:setEmitterLifetime(self.duration)
			self.system:setEmissionRate(self.rate)
			self.system:setLinearAcceleration(self.linear_accel_x, self.linear_accel_y)
			self.system:setLinearDamping(self.linear_damp_x, self.linear_damp_y)
			self.system:setPosition(self.spawn_x, self.spawn_y)
			
			local c1 = Draw._parseColorArgs(self.color)
			local c2 = Draw._parseColorArgs(self.end_color)
			self.system:setColors(c1[1], c1[2], c1[3], c1[4], c2[1], c2[2], c2[3], c2[4])

			love.graphics.draw(self.system, self.x, self.y)
		end
	end
}

return Repeater