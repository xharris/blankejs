View = Class{
	init = function(self, follow_entity)
		-- the final draw position
		self.x = 0
		self.y = 0
		self.top = 0
		self.left = 0
		self.bottom = 0
		self.right = 0

		self._port_w = game_width
		self._port_h = game_height

		self.port_width = -1
		self.port_height = -1

        self.follow_entity = follow_entity
        self.offset_x = 0
        self.offset_y = 0

        local w,h = self:getSize()

        -- ways for camera to move towards x,y
        self.move_type = 'snap'
        -- lockX
        self.lock_rect = {0,0,w,h}

        -- shake variables
        self.shake_x = 0
        self.shake_y = 0
        self.shake_tween = nil
        self.shake_speed = 50
        self.shake_duration = 1 -- seconds

        self.angle = 0
        self.scale_x = 1
        self.scale_y = 1

        self._half_w, self._half_h = math.floor(w/2), math.floor(h/2)

        self.onPropSet['zoom'] = function(self, v)
        	self.scale_x = v
        	self.scale_y = v
    	end
    	self.onPropGet['zoom'] = function() return 1 end

        _addGameObject('view',self)
	end,

	getSize = function(self)
		return cond(self.port_width >= 0, self.port_width, self._port_w), cond(self.port_height >= 0, self.port_height, self._port_h)
	end,

	follow = function(self, entity)
		self.follow_entity = entity
	end,

	moveTo = function(self, x, y)
		self.follow_entity = nil

	end,

	shake = function(self, x, y)
		if self.shake_tween == nil then 
			self.shake_x = x
			self.shake_y = y
			self.shake_tween = Tween(self, {shake_x=0, shake_y=0}, self.shake_duration)
			self.shake_tween.onFinish = function()
				self.shake_tween:destroy()
				self.shake_tween = nil
			end
			self.shake_tween:play()
		end

		return self
	end,

	update = function(self, dt)
		self._port_w = game_width
		self._port_h = game_height
		local follow_x, follow_y = 0, 0

		if self.follow_entity then
			follow_x, follow_y = self.follow_entity.x, self.follow_entity.y
		else
			follow_x, follow_y = self.x, self.y
		end

		-- shake calculations
		local shake_x, shake_y = 0, 0

		if self.shake_x > 0 then
			shake_x = sinusoidal(-self.shake_x, self.shake_x, self.shake_speed, self.shake_x / 2)
		end
		if self.shake_y > 0 then
			shake_y = sinusoidal(-self.shake_y, self.shake_y, self.shake_speed, self.shake_y / 2)
		end

		local target_x = follow_x + self.offset_x + shake_x
		local target_y = follow_y + self.offset_y + shake_y

		
		self.x = math.floor(target_x)
		self.y = math.floor(target_y)

		self.top = self.y - self._half_h
		self.left = self.x - self._half_w

		local w,h = self:getSize()

		self.right = self.left + w
		self.bottom = self.top + h
	end,

	_transform = love.math.newTransform(),
	on = function(self)
		local w,h = self:getSize()
		self._half_w, self._half_h = math.floor(w/2), math.floor(h/2)
		Draw.push()

		View._transform:reset()
		View._transform:translate(self._half_w, self._half_h)
		View._transform:scale(self.scale_x, self.scale_y)
		View._transform:rotate(self.angle)
		View._transform:translate(-self.x, -self.y)

		if Canvas._applied == 1 then
            love.graphics.replaceTransform(View._transform)
		end
	end,

	off = function(self)
		Draw.pop()
	end,

	draw = function(self, fn)
		self:on()
		fn()
		self:off()
	end
}

return View