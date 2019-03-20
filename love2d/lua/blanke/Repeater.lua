local floor = math.floor

local calcProp = function(particle, t, attribute, spd)
	local attr = particle[attribute]
	-- store starting value
	if attr[4] == nil then particle[attribute][4] = attr[1] end
	-- start == end. don't tween
	if attr[4] == attr[2] then return attr[1] end
	return Tween.tween_func[attr[3]](attr[1], attr[2] - attr[4], particle.duration[1] * (spd or 1)*1000, (t)*1000)
end

Repeater = Class{
	init = function(self, texture, options)
		local val = function(x) return {x,x,'linear'} end
		-- vvv Things that each particle will inherit vvv
		self.changed = {}
		self.options = {
			is_random = {},
			-- starting value
			x = val(0), y = val(0),
			duration = val(3), -- seconds
			-- movement
			direction = val(0), speed = val(0),
			-- position
			offset_x = val(0), offset_y = val(0),
			-- color
			r = val(1), g = val(1), b = val(1), a = val(1),
			-- Sprite only
			spr_frame = val(0), spr_speed = val(-1)
		}
		--- END

		self.current_t = 0
		self.rate = 0
		self.emit_count = 1
		self.rate_dt = 0
		self.count = 0
		self.particles = {} -- list of particles and their info

		-- values that can have a min/max
		self.tweenable_options = {'direction','speed','offset_x','offset_y','r','g','b','a','spr_frame'}
		table.update(self.options, options or {})

		local checkPropType = function(name, value, index)
			local ret = value
			index = 1
			if name == "is_random" then return ret end

			if name:endsWith('2') then
				name = string.sub(name, 1,-2)
				index = 2
			end

			local opt_type = type(self.options[name])
			if opt_type ~= "table" or (opt_type == "table" and #self.options[name] == 2) then
				self.options[name] = {value,value,'linear'}
			end
			local val_type = type(value)
			if val_type ~= "table" or (val_type == "table" and #self.options[name] == 2) then
				ret = value
				-- sprite_frame will end at last frame, and won't be seen at all without this
				if index == 2 and name == "spr_frame" then
					ret = value + 1
				end
			end

			-- determine random range
			if not self.options.is_random[name] then self.options.is_random[name] = {false,false} end
			if val_type == "table" and #value == 2 then
				self.options.is_random[name][index] = true
			else 
				self.options.is_random[name][index] = false
			end

			if index == 2 then
				self.options[name..'2'] = nil
			end
			return ret
		end

		for name, value in pairs(self.options) do
			checkPropType(name, value)

			-- create Setter
			self.onPropSet[name] = function(self, v)
				self.options[name][1] = checkPropType(name, v)
				self.changed[name] = true
			end
			-- create Getter
			self.onPropGet[name] = function()
				return self.options[name][1]
			end
			if table.hasValue(self.tweenable_options, name) then
				-- create Setter for max value
				self.onPropSet[name..'2'] = function(self, v)
					self.options[name][2] = checkPropType(name..'2', v, 2)
					self.changed[name] = true
				end
				self.onPropGet[name..'2'] = function()
					return self.options[name][2]
				end 	
			end
		end

		self:setTexture(texture)

		_addGameObject("repeater",self)
	end,

	update = function(self, dt)
		self:updateSpriteTexture()
		self:updateEntityTexture()
		self.current_t = self.current_t + dt

		local dir_x,dir_y, off_x,off_y

		for p, part in ipairs(self.particles) do
			local part = self.particles[p]
			if part then
				local sprite_batch = self.real_texture
				if part.spr_index ~= nil then 
					sprite_batch = self.texture_list[part.spr_index]
				end 

				local prop = function(p, spd) return calcProp(part, self.current_t - part.start_t, p, spd) end

				-- end of particle lifetime
				if (self.current_t - part.start_t) > part.duration[1] then 
					sprite_batch:set(part.id,0,0,0,0,0)
					table.remove(self.particles, p)-- self.particles[p] = nil
					self.count = self.count - 1
				else 
					-- update position
					dir_x, dir_y = direction_x(prop('direction'), prop('speed')), direction_y(prop('direction'), prop('speed'))
					off_x, off_y = prop('offset_x'), prop('offset_y')

					if self.sprite_texture then
						-- NOTE : atm, the duration of the particle depends on the 'duration' property. it will speed up if the duration is lower. change or naw?
						local frame = floor(prop('spr_frame',prop('spr_speed')))
						part.quad = self.texture.anim.frames[(frame-1) % self.texture.frame_count +1]
					end

					local x = prop('x') + off_x + dir_x * dt
					local y = prop('y') + off_y + dir_y * dt
				
					part.spritebatch:setColor(prop('r'), prop('g'), prop('b'), prop('a'))

					if self.sprite_texture then
						part.spritebatch:set(part.id, part.quad, x, y, 0,
							self.texture.xscale,self.texture.yscale,
							-self.texture.xoffset,-self.texture.yoffset)
					elseif self.entity_texture then
						part.spritebatch:set(part.id, x, y, 0,
							self.texture.sprite_xscale,self.texture.sprite_yscale,
							self.texture.sprite_xoffset,self.texture.sprite_yoffset)
					else
						part.spritebatch:set(part.id, x, y)
					end
				end
			end
		end

		-- rate ~= 0, spawn a new particle
		if self.rate ~= 0 then
			if self.rate_dt > 0 then
				self.rate_dt = self.rate_dt - dt 
			else 
				self.rate_dt = self.rate

				self:emit(self.emit_count)
			end
		end
	end,

	updateSpriteTexture = function(self)
		if not self.sprite_texture then return end

		local f = cond(self.spr_frame == 0, self.texture.frame, floor(self.spr_frame))

		self.quad = self.texture.anim.frames[f]
		self.options.quad = self.quad
	end,

	updateEntityTexture = function(self)
		if not self.entity_texture then return end 

		local spr_index = self.texture.sprite_index
		self.real_texture = self.texture_list[spr_index]

		-- all new particles will inherit these values
		self.options.spritebatch = self.real_texture
		self.options.quad = self.quad
	end,

	setTexture = function(self, texture)
		self.texture = texture
		self.real_texture = nil
		self.quad = nil
		self.entity_texture = false
		self.sprite_texture = false

		if type(texture) == "table" and texture.classname then
			if texture.classname == "Image" then
				self.real_texture = love.graphics.newSpriteBatch(texture.image)
				self.options.spritebatch = self.real_texture
			
			elseif texture._entity then
				self.entity_texture = true
				self.texture_list = {}
				for name, sprite in pairs(texture._sprites) do
					self.texture_list[name] = love.graphics.newSpriteBatch(texture._images[name].image)
				end
				self:updateEntityTexture()

			elseif texture.classname == "Canvas" then
				self.real_texture = love.graphics.newSpriteBatch(texture.canvas)
				self.options.spritebatch = self.real_texture

			elseif texture.classname == "Sprite" then
				self.sprite_texture = true
				self.real_texture = love.graphics.newSpriteBatch(texture.image())
				self.options.spritebatch = self.real_texture
			end
		end
	end,

	emit = function(self, count)
		if self.entity_texture and not self.quad then return end

		count = count or self.emit_count
		local new_particle
		for i = 1, count do
			new_p = table.deepcopy(self.options, function(k, v)
				local v1, v2, opt, new_v = v[1], v[2], self.options, {v[1],v[2],v[3]}
				if opt.is_random[k] then
					if opt.is_random[k][1] then
						new_v[1] = randRange(unpack(new_v[1]))
						if not opt.is_random[k][2] then 
							new_v[2] = new_v[1]
						end
					end 
					if opt.is_random[k][2] then
						new_v[2] = randRange(unpack(new_v[2]))
						if not opt.is_random[k][1] then 
							new_v[1] = new_v[2]
						end
					end 
					return new_v
				end
			end)

			if self.sprite_texture then
				for i = 1, 2 do
					-- non-negative sprite speed
					if new_p.spr_speed[i] < 0 then new_p.spr_speed[i] = self.texture.speed end
					-- non-negative sprite duration
					if new_p.duration[i] < 0 then new_p.duration[i] = self.texture.duration end

					--new_p.duration[i] = self.texture.duration / self.texture.sprite_speed * new_p.spr_speed[i]
					--new_p.spr_speed[i] = new_p.duration[i] / self.texture.duration * self.texture.sprite_speed
				end	

				if new_p.spr_frame[1] == 0 then new_p.spr_frame[1] = 1 end
				if new_p.spr_frame[2] == 0 then new_p.spr_frame[2] = self.texture.frame_count+1 end--*(new_p.duration[1] / self.texture.duration)+1 end
			end
			
			if new_p.quad ~= nil then
				new_p.id = new_p.spritebatch:add(new_p.quad, new_p.x[1], new_p.y[1])
			else 
				new_p.id = new_p.spritebatch:add(new_p.x[1], new_p.y[1])
			end
			new_p.start_t = self.current_t 

			self.count = self.count + 1
			table.insert(self.particles, new_p)
		end
	end,

	draw = function(self)
		if self.entity_texture then 
			for t, texture in pairs(self.texture_list) do 
				love.graphics.draw(texture)
			end 
		else
			love.graphics.draw(self.real_texture)
		end 
	end
}

return Repeater