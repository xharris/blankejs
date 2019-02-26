Repeater = Class{
	init = function(self, texture, options)
		local val = function(x) return {x,x,'linear'} end
		-- vvv Things that each particle will inherit vvv
		self.options = {
			-- starting value
			x = val(0), y = val(0),
			duration = val(3), -- seconds
			-- movement
			direction = val(0), speed = val(0),
			-- position
			offset_x = val(0), offset_y = val(0)
		}
		self.tween_ref = {}
		--- END

		self.current_t = 0
		self.rate = 0
		self.rate_dt = 0
		self:setTexture(texture)
		self.particles = {} -- list of particles and their info

		-- values that can have a min/max
		self.minmax_options = {'direction','speed'}
		table.update(self.options, options or {})
		local function createSetGet(name)
			
		end
		for name, value in pairs(self.options) do
			-- create Setter
			self.onPropSet[name] = function(self, v)
				self.options[name][1] = v
			end
			-- create Getter
			self.onPropGet[name] = function()
				return self.options[name][1]
			end
			if table.hasValue(self.minmax_options, name) then
				-- create Setter for max value
				self.onPropSet[name..'2'] = function(self, v)
					if not self.options[name] then 
						self.options[name] = {v,v,'linear'}
					else 
						self.options[name][2] = v 
					end
				end
				self.onPropGet[name..'2'] = function()
					return self.options[name][2]
				end 	
			end
		end

		_addGameObject("repeater",self)
	end,

	update = function(self, dt)
		self.current_t = self.current_t + dt 	
		for p, part in ipairs(self.particles) do 
			local sprite_batch = self.real_texture
			if part.spr_index ~= nil then 
				sprite_batch = self.texture_list[part.spr_index]
			end 

			-- end of particle lifetime
			if (self.current_t - part.start_t) > part.duration[1] then 
				sprite_batch:set(part.id,0,0,0,0,0)
				self.particles[p] = nil
			
			else 
				-- update position
				part.x[1], part.y[1] = part.x[1] + direction_x(part.direction[1], part.speed[1]), part.y[1] + direction_y(part.direction[1], part.speed[1])
			
				if part.quad ~= nil then
					part.spritebatch:set(part.id, part.quad, part.x[1], part.y[1])
				else 
					part.spritebatch:set(part.id, part.x[1], part.y[1])
				end
			
			end
		end

		-- rate ~= 0, spawn a new particle
		if self.rate ~= 0 then self.rate_dt = self.rate_dt - dt end
		if self.rate ~= 0 and self.rate_dt == 0 then 
			self.rate_dt = self.rate

			self:emit()
		end

		self:updateEntityTexture()
	end,

	updateEntityTexture = function(self)
		if not self.entity_texture then return end 

		local spr_index = self.texture.sprite_index
		self.real_texture = self.texture_list[spr_index]
		self.quad = self.texture._sprites[spr_index].frames[self.texture.sprite_frame+1]

		-- all new particles will inherit these values
		self.options.spritebatch = self.real_texture
		self.options.quad = self.quad
	end,

	setTexture = function(self, texture)
		self.texture = texture
		self.real_texture = nil
		self.quad = nil
		self.entity_texture = false

		if type(texture) == "table" and texture.classname then
			if texture.classname == "Image" then
				self.real_texture = love.graphics.newSpriteBatch(texture.image)
			
			elseif texture._entity then
				self.entity_texture = true
				self.texture_list = {}
				for name, sprite in pairs(texture._sprites) do
					self.texture_list[name] = love.graphics.newSpriteBatch(texture._images[name].image)
				end
				self:updateEntityTexture()

			elseif texture.classname == "Canvas" then
				self.real_texture = love.graphics.newSpriteBatch(texture.canvas)

			end
		end
	end,

	emit = function(self, count)
		count = count or 1
		local new_particle
		for i = 1, count do

			new_p = table.deepcopy(self.options)
			
			if new_p.quad ~= nil then
				new_p.id = new_p.spritebatch:add(new_p.quad, new_p.x[1], new_p.y[1])
			else 
				new_p.id = new_p.spritebatch:add(new_p.x[1], new_p.y[1])
			end
			new_p.start_t = self.current_t 

			self.particles[#self.particles+1] = new_p
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