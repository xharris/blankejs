Repeater = Class{
	init = function(self, texture, options)
		self:setTexture(texture)
		self.particles = {} -- list of particles and their info

		local val = function(x) return {x,x,'linear'} end
		-- vvv Things that each particle will inherit vvv
		self.options = {
			-- starting value
			x = val(0), y = val(0),
			-- movement
			direction = val(0), speed = val(0)
		}
		self.tween_ref = {}
		--- END
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
		self:updateEntityTexture()
	end,

	updateEntityTexture = function(self)
		if not self.entity_texture then return end 

		local spr_index = self.texture.sprite_index
		self.real_texture = self.texture_list[spr_index]
		self.quad = self.texture._sprites[spr_index].frames[self.texture.sprite_frame]
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
			
			if self.quad ~= nil then
				Debug.log("quad")
				new_p.id = self.real_texture:add(self.quad, new_p.x[1], new_p.y[1])
			else 
				new_p.id = self.real_texture:add(new_p.x[1], new_p.y[1])
			end

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