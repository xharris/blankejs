local cos = math.cos
local sin = math.sin
local rad = math.rad

Entity = Class{
	x = 0,
	y = 0,
	net_sync_vars = {'x', 'y', 'persistent'},
	net_excludes = {'^_images$','^_sprites$','^sprite$','previous$','start$','^shapes$','^collision','^onCollision$','^is_net_entity$'},
    _init = function(self, parent) 
    	self._entity = true   
    	self.classname = ifndef(self.classname, 'entity')

    	self._destroyed = false
	    self._images = {}		
		self._sprites = {} 			-- is actually the animations
		self.show_debug = false
		self.scene_show_debug = false

		-- x and y coordinate of sprite
		self.x = ifndef(self.x, Entity.x)
		self.y = ifndef(self.y, Entity.y)
		self.parent = parent

		Entity.x = 0
		Entity.y = 0

		-- sprite/animation variables
		self._call_sprite_update = {}
		self._sprite_prev = '' 				-- previously used sprite
		self.sprite = {}	
		self.sprite_angle = 0		
		self.sprite_xscale = 1
		self.sprite_yscale = 1
		self.sprite_xoffset = 0
		self.sprite_yoffset = 0
		self.sprite_xshear = 0
		self.sprite_yshear = 0
		self.sprite_color = {255,255,255}
		self.sprite_alpha = 255
		self.sprite_speed = 1
		self.sprite_frame = 0
		self.sprite_width = 0
		self.sprite_height = 0

		-- movement variables
		self.direction = 0
		self.friction = 0
		self.gravity = 0
		self.gravity_direction = 90
		self.hspeed = 0
		self.vspeed = 0
		self.speed = 0
		self.xprevious = 0
		self.yprevious = 0
		self.xstart = self.x
		self.ystart = self.y

		-- collision
		self.shapes = {}
		self._main_shape = ''
		self.collisions = {}
		self.collisionStop = nil
		self.collisionStopX = nil
		self.collisionStopY = nil	

		self.onCollision = {["*"] = function() end}

    	_addGameObject('entity', self)
    end,

    _post_init = function(self)
		if not self.sprite_index then
			self.sprite_index = table.keys(self._sprites)[1]
		end
    end,

    __newindex = function(self, k, v)
    	if k == "sprite_index" then
			self:refreshSpriteDims(v)
    	end
    	rawset(self, k, v)
    end,	

    __eq = function(self, other)
    	return (self.uuid == other.uuid)
    end,

    destroy = function(self)
    	-- destroy hitboxes
    	for s, shape in pairs(self.shapes) do
    		shape:destroy()
    	end

    	_destroyGameObject('entity', self)
    end,

    onNetAdd = function(self)
    	self:netSync("x","y")
    end,

    _update = function(self, dt)
    	if self._destroyed then return end

    	-- subtract friction
    	if self.hspeed ~= 0 then 
    		self.hspeed = self.hspeed + -(self.hspeed * self.friction)
    		if self.friction < 1 and self.friction > 0 and math.abs(self.hspeed) <= 50 then
    			self.hspeed = 0
    		end
    	end

    	if self.update then
			self:update(dt)
		end

    	if self._destroyed then return end -- call again in case entity is destroyed during update

		if not self.pause then			
			-- clear sprite update call list
			for sprite_name, val in pairs(self._call_sprite_update) do
				--[[
				if not self._sprites[sprite_name] then
					self._sprites[sprite_name] = {}
					self._sprites[sprite_name].gotoFrame = function() end
				end]]

				self._sprites[sprite_name]:update(ifndef(self.sprite[sprite_name].speed, self.sprite_speed)*dt)
				self._call_sprite_update[sprite_name] = nil
			end
		end

		-- x/y extra coordinates
		if self.xstart == 0 then
			self.xstart = self.x
		end
		if self.ystart == 0 then
			self.ystart = self.y
		end

		-- check for collisions
		if not self.pause then
			-- calculate speed/direction
			local speedx, speedy = 0,0
			if speed ~= 0 then
				speedx = self.speed * cos(rad(self.direction))
				speedy = self.speed * sin(rad(self.direction))
			end

			-- calculate gravity/gravity_direction
			local gravx, gravy = 0,0
			if self.gravity ~= 0 then
				gravx = math.floor(self.gravity * cos(rad(self.gravity_direction)))
				gravy = math.floor(self.gravity * sin(rad(self.gravity_direction)))
			end

			-- add gravity to hspeed/vspeed
			if gravx ~= 0 then self.hspeed = self.hspeed + gravx end
			if gravy ~= 0 then self.vspeed = self.vspeed + gravy end

			-- move shapes if the x/y is different
			if self.xprevious ~= self.x or self.yprevious ~= self.y then
				for s, shape in pairs(self.shapes) do
					-- account for x/y offset?
					shape:moveTo(self.x, self.y)
				end
			end
        
			self.xprevious = self.x
			self.yprevious = self.y

			local dx = self.hspeed + speedx
			local dy = self.vspeed + speedy

			-- move all shapes
			for s, shape in pairs(self.shapes) do
				shape:move(dx*dt, dy*dt)
			end

			local _main_shape = self.shapes[self._main_shape]
			
			self.collisions = {}
			for name, fn in pairs(self.onCollision) do
				-- make sure it actually exists
				if self.shapes[name] ~= nil and self.shapes[name]._enabled then
					local obj_shape = self.shapes[name]:getHCShape()

					local collisions = HC.neighbors(obj_shape)
					for other in pairs(collisions) do
					    local collides, dx, dy = obj_shape:collidesWith(other)
					    if collides and not other.tag:contains(self.classname) then
		                	local sep_vec = {x=dx, y=dy, point_x=0, point_y=0}

		                	-- calculate location of collision
		                	local bx, by, bw, bh = unpack(obj_shape.box)
		                	bw = bw - bx
		                	bh = bh - by
		                	if dx < 0 then sep_vec.point_y = by; sep_vec.point_x = (bw + dx) end
		                	if dx > 0 then sep_vec.point_y = by; sep_vec.point_x = dx end
		                	if dy < 0 then sep_vec.point_x = bx; sep_vec.point_y = (bh + dy) end
		                	if dy > 0 then sep_vec.point_x = bx; sep_vec.point_y = dy end

		                	self.collisions[name] = ifndef(self.collisions[name], {})
					    	self.collisions[name][other.tag] = sep_vec

							-- collision action functions
							self.collisionStopX = function(self)
								for name, shape in pairs(self.shapes) do
									shape:move(sep_vec.x, 0)
								end
					            self.hspeed = 0
					            speedx = 0
					            dx = 0
							end

							self.collisionStopY = function(self)
								for name, shape in pairs(self.shapes) do
									shape:move(0, sep_vec.y)
								end
					            self.vspeed = 0
					            speedy = 0
					            dy = 0
							end
							
							self.collisionStop = function(self)
								self:collisionStopX()
								self:collisionStopY()
							end

							-- call users collision callback if it exists
							fn(other, sep_vec)
						end
					end
				end
			end

			-- set position of sprite
			if self.shapes[self._main_shape] ~= nil and self.shapes[self._main_shape]._enabled then
				self.x, self.y = self.shapes[self._main_shape]:center()
			else
				self.x = self.x + dx*dt
				self.y = self.y + dy*dt
			end

			if self.speed > 0 then
				self.speed = self.speed - (self.speed * self.friction)*dt
			end
		end

		self:netSync()

		return self
	end,

	hadCollision = function(self, self_name, other_name)
		if not self.collisions[self_name] then return false end
		for name, sep_vec in pairs(self.collisions[self_name]) do
			if name:contains(other_name) then return true end
		end
	end,

	getCollisions = function(self, shape_name)
		if self.shapes[shape_name] then
			local hc_shape = self.shapes[shape_name]:getHCShape()
			return HC.collisions(self.shapes[shape_name])
		end
		return {}
	end,

	debugSprite = function(self, sprite_index)
		local info = self:getSpriteInfo(sprite_index)

		local sx = -info.xoffset
		local sy = -info.yoffset

		Draw.stack(function()
			Draw.translate(self.x, self.y)
			Draw.rotate(info.angle)
			Draw.shear(info.xshear, info.yshear)
			Draw.scale(info.xscale, info.yscale)

			-- draw sprite outline
			Draw.setColor(0,1,0,2/3)
			Draw.setLineWidth(1)
			if self._sprites[sprite_index] then
				local sprite_width, sprite_height = self:getSpriteDims(sprite_index)
				love.graphics.rectangle("line", -sx, -sy, sprite_width, sprite_height)
			end
			-- draw origin point
			love.graphics.circle("line", 0, 0, 2)
		end)
		return self
	end,

	debugCollision = function(self)
		-- draw collision shapes
		Draw.stack(function()
			for s, shape in pairs(self.shapes) do
				shape:draw("line")
			end
		end)
		return self
	end,

	getSpriteDims = function(self, sprite_index)
		return self._sprites[sprite_index]:getDimensions()
	end,

	getSpriteInfo = function(self, sprite_index)
		if not self.sprite[sprite_index] then return end

		local info = table.deepcopy(self.sprite[sprite_index])

		local vars = {'width','height','angle','xscale','yscale','xoffset','yoffset','xshear','yshear','color','alpha','speed'}
		for v, var in ipairs(vars) do
			if info[var] == nil then
				info[var] = self['sprite_'..var]
			else
				if var == 'xoffset' or var == 'yoffset' then
					info[var] = self['sprite_'..var] + info[var]
				end
			end
		end

		return info
	end,

	drawSprite = function(self, sprite_index)
		-- if no sprite is given, draw them all
		if not sprite_index then
			if self.sprite_index then
				self:drawSprite(self.sprite_index)
			end
		end
		local sprite = self._sprites[sprite_index]
		local info = self:getSpriteInfo(sprite_index)

		if self.show_debug or self.scene_show_debug then self:debugCollision() end

		if info and sprite then
			self._call_sprite_update[sprite_index] = true

			local sep_frame = false
			if self.sprite[sprite_index].frame ~= nil then
				sep_frame = true
			end

			if info.speed == 0 then
				if sep_frame then
					sprite:gotoFrame(info.frame)
				else
					sprite:gotoFrame(self.sprite_frame)
				end
			end

			if not sep_frame then
				self.sprite_frame = sprite.position -- TODO: what about sprites with different amount of frames. does it even matter?
			end

			-- draw current sprite (image, x,y, angle, sx, sy, ox, oy, kx, ky) s=scale, o=origin, k=shear
			local img = self._images[sprite_index]
			Draw.stack(function()
				if self.show_debug or self.scene_show_debug then self:debugSprite(sprite_index) end

				Draw.setColor(info.color[1], info.color[2], info.color[3], ifndef(info.color[4], info.alpha))
				--love.graphics.setColor(info.color[1], info.color[2], info.color[3], ifndef(info.color[4], info.alpha))
				
				-- is it an Animation or an Image
				if img then
					local draw_x, draw_y = math.floor(self.x), math.floor(self.y)
					if sprite.update ~= nil then
						sprite:draw(img(), draw_x, draw_y, math.rad(info.angle), info.xscale, info.yscale, -math.floor(info.xoffset), -math.floor(info.yoffset), info.xshear, info.yshear)
					else
						love.graphics.draw(img(), draw_x, draw_y, math.rad(info.angle), info.xscale, info.yscale, -math.floor(info.xoffset), -math.floor(info.yoffset), info.xshear, info.yshear)
					end
				end
			end)
		else
			self.sprite_width = 0
			self.sprite_height = 0
		end
	end,

	draw = function(self)
		if self._destroyed then return end

		if self.preDraw then
			self:preDraw()
		end

		self:drawSprite()

		if self.postDraw then
			self:postDraw()
		end
		return self
	end,

	animationMatch = function(self, src, dest)
		for key, val in pairs(self.sprite[src]) do
			self.sprite[dest][key] = val
		end
	end,

	addAnimation = function(self, args)
		-- main args
		local ani_name = args.name
		local name = args.image
		local frames = ifndef(args.frames, {1,1})
		-- other args
		local offset = ifndef(args.offset, {0,0})
		local left = offset[1]
		local top = offset[2]
		local border = ifndef(args.border, 0)
		local speed = ifndef(args.speed, 0.1)

		if Image.exists(name) then
			local image = Image(name)
			local frame_size = ifndef(args.frame_size, {image.width, image.height})
		    local grid = anim8.newGrid(frame_size[1], frame_size[2], image.width, image.height, left, top, border)
			local sprite = anim8.newAnimation(grid(unpack(frames)), speed)

			self._images[ani_name] = image
			self._sprites[ani_name] = sprite

			self:refreshSpriteDims(ani_name)
			self.sprite[ani_name] = {width=self.sprite_width, height=self.sprite_height}
		end
		return self
	end,

	refreshSpriteDims = function(self, name)
		if self._sprites[name] then
			local anim_w, anim_h = self._sprites[name]:getDimensions()
			self.sprite_width, self.sprite_height = ifndef(anim_w, 0), ifndef(anim_h, 0)
		end
	end,

	-- add a collision shape
	-- str shape: rectangle, polygon, circle, point
	-- str name: reference name of shape
	addShape = function(self, name, shape, args, tag)
		tag = ifndef(tag, self.classname..'.'..name)
		local new_hitbox = Hitbox(shape, args, tag, 0, 0)
		new_hitbox:setParent(self)
		new_hitbox:moveTo(self.x, self.y)
		self.shapes[name] = new_hitbox

		if not self._main_shape then
			self:setMainShape(name)
		end
		return self
	end,

	-- remove a collision shape
	removeShape = function(self, name)
		if self.shapes[name] ~= nil then
			self.shapes[name]:disable()
		end
		return self
	end,

	-- the shape that the sprite will follow
	setMainShape = function(self, name) 
		if self.shapes[name] ~= nil then
			self._main_shape = name
		end 
		return self
	end,

	distancePoint = function(self, x, y)
		return math.sqrt((x - self.x)^2 + (y - self.y)^2)
	end,

	-- other : Entity object
	-- returns distance between center of self and other object in pixels
	distance = function(self, other)
		return self:distancePoint(other.x, other.y)
	end,

	-- self direction and speed will be set towards the given point
	-- this method will not set the speed back to 0 
	moveTowardsPoint = function(self, x, y, speed)
		self.direction = math.deg(math.atan2(y - self.y, x - self.x))
		self.speed = speed
		return self
	end,
    
    -- checks if the point is inside the current sprite
    containsPoint = function(self, x, y)
    	for name, sprite in pairs(self.sprite) do
	        if x >= self.x and y >= self.y and x < self.x + sprite.width and  y < self.y + sprite.height then
    	        return true
        	end
        end
        return false
    end
}

return Entity