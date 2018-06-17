View = Class{
	global_drag_enable = false,
	init = function (self)
		self._dt = 0

		self.disabled = false

		self.camera = Camera(0, 0)
		self.follow_entity = nil
		self.follow_x = 0
		self.follow_y = 0
		self.offset_x = 0
		self.offset_y = 0
		self.drag_offset_x = 0
		self.drag_offset_y = 0 

		self.top = 0
		self.bottom = 0

		self.motion_type = 'none' -- linear, smooth
		self.speed = 1 
		self.max_distance = 0
		self._last_motion_type = self.motion_type
		self._last_speed = self.speed
		self._smoother = nil

		self.angle = 0
		self.rot_speed = 5
		self.rot_type = 'none'
        
		self.scale_x = 1
        self.scale_y = 1
		self.zoom_speed = .5
		self.zoom_type = 'none'
		self.zoom_callback = nil
        
        self.port_x = 0
        self.port_y = 0
        self.port_width = game_width 
        self.port_height = game_height
        self.noclip = true
        
        self.shake_x = 0
        self.shake_y = 0
        self.shake_intensity = 7
        self.shake_falloff = 2.5
        self.shake_type = 'smooth'

        self.draggable = false
	    self.drag_input = nil
        self._dragging = false
        self._view_initial_pos = {0,0}
		self._initial_mouse_pos = {0,0}
		self._enable_grid = BlankE._ide_mode
        self._is_a_fake = false
        self._is_drawing = 0

        if BlankE._ide_mode then
        	self.drag_input = Input('mouse.3','space')
	    end

        _addGameObject('view',self)
	end,

	-- return camera position
	position = function(self)
		if self.camera then
			return self.camera:position()
		else
			return 0, 0
		end
	end,

	follow = function(self, entity)
		self.follow_entity = entity

		self:update()
	end,

	moveTo = function(self, entity) 
		if entity then
			self.follow_x = entity.x
			self.follow_y = entity.y

			self:update()
		end
	end,	

	moveToPosition = function(self, x, y, fromUpdate)
		self.follow_x = x
		self.follow_y = y

		-- if called from 'update', fromUpdate = dt
		if not fromUpdate then
			self:update()
		end
	end,

	snapTo = function(self, entity)
		self:snapToPosition(entity.x, entity.y)
	end,

	snapToPosition = function(self, x, y)
		if self.camera then
			self.camera:lookAt(x, y)
		end
	end,

	rotateTo = function(self, angle)
		self.angle = angle
	end,

	zoom = function(self, scale_x, scale_y, callback)
        if not scale_y then
            scale_y = scale_x
        end
        
        self.scale_x = scale_x
		self.scale_y = scale_y
		self.zoom_callback = callback
	end,
    
    mousePosition = function(self)
    	if self.camera then
    		local mx, my = self.camera:mousePosition()
    		if self.follow_entity then
		        return (game_width/2)-(self.port_width/2)+mx, (game_height/2)-(self.port_height/2)+my
		    end
	    end
	    return 0, 0
    end,
    
    shake = function(self, x, y)
        if not y then
            y = x
        end
        
        self.shake_x = x
        self.shake_y = y
    end,
    
    squeezeH = function(self, amt)
        self.squeeze_x = math.abs(amt)
        self._squeeze_dt = 0
    end,

	update = function(self, dt)
		if not self.camera then return end

		-- dragging
		if BlankE._ide_mode and self.drag_input == nil then
        	self.drag_input = Input('mouse.3','space')
	    end

		if (View.global_drag_enable or self.draggable) and self.drag_input ~= nil then
			
			if self.drag_input() then
	    		-- on down
		    	if not self._dragging then
		    		self._dragging = true
		    		self._view_initial_pos = {self.drag_offset_x,self.drag_offset_y}
		    		self._initial_mouse_pos = {love.mouse.getX(), love.mouse.getY()}
		    		--
		    	end
		    	-- on hold
		    	if self._dragging then
		    		local _drag_dist = {love.mouse.getX()-self._initial_mouse_pos[1], love.mouse.getY()-self._initial_mouse_pos[2]}
		    		self.drag_offset_x = self._view_initial_pos[1] - _drag_dist[1]
		    		self.drag_offset_y = self._view_initial_pos[2] - _drag_dist[2]
		    		--Scene._fake_view_start = {self:position()}
		    	end
		    end
	    	-- on release
	    	if not self.drag_input() and self._dragging then
	    		self._dragging = false
	    	end
	    end

		if self.follow_entity then
			local follow_x = self.follow_entity.x
			local follow_y = self.follow_entity.y
			self:moveToPosition(follow_x, follow_y, true)
		end

		local shake_x, shake_y = 0,0

		if not BlankE.pause then

		-- determine the smoother to use 
		if self._last_speed ~= self.speed or self._last_motion_type ~= self.motion_type then
			if self.motion_type == 'none' then
				self._smoother = Camera.smooth.none()

			elseif self.motion_type == 'linear' then
				self._smoother = Camera.smooth.linear(self.speed)

			elseif self.motion_type == 'damped' then
				self._smoother = Camera.smooth.damped(self.speed)

			end
		end

		-- rotation
		if math.deg(self.camera.rot) ~= self.angle then
			local new_angle
			if self.rot_type == 'none' then
				new_angle = self.angle

			elseif self.rot_type == 'damped' then
				new_angle = lerp(math.deg(self.camera.rot), self.angle, self.rot_speed, self._dt)

			end
			self.camera:rotateTo(math.rad(new_angle))
		end

		-- zoom
        if self.scale_y == nil then
            self.scale_y = self.scale_x
        end
        
		if self.camera.scale_x ~= self.scale_x or self.camera.scale_y ~= self.scale_y then
			local new_zoom_x = self.scale_x
            local new_zoom_y = self.scale_y
			if self.zoom_type == 'none' then
				new_zoom_x = self.scale_x
                new_zoom_y = self.scale_y

			elseif self.zoom_type == 'damped' then
				new_zoom_x = lerp(self.camera.scale_x, self.scale_x, self.zoom_speed, self._dt)
				new_zoom_y = lerp(self.camera.scale_y, self.scale_y, self.zoom_speed, self._dt)
				local abs = math.abs
				if abs(self.scale_x - new_zoom_x) < .01 and abs(self.scale_y - new_zoom_y) < .01 then
					new_zoom_x = self.scale_x
					new_zoom_y = self.scale_y
				end
			end
			self.camera:zoomTo(new_zoom_x, new_zoom_y)

			if new_zoom_x == self.scale_x and new_zoom_y == self.scale_y and self.zoom_callback then
				self.zoom_callback()
				self.zoom_callback = nil
			end
		end
        
        -- shake
        local modifier = 1
        if self.shake_type == 'smooth' then
            modifier = 1
        elseif self.shake_type == 'rigid' then
            modifier = (random_range(1, 20)/10)
        end
        
        shake_x = sinusoidal(-self.shake_x, self.shake_x, self.shake_intensity * modifier, 0)
        shake_y = sinusoidal(-self.shake_y, self.shake_y, self.shake_intensity * modifier, 0)
        
        if self.shake_y > 0 then
            self.shake_y = lerp(self.shake_y, 0 ,dt*self.shake_falloff)
        end
        
        if self.shake_x > 0 then
            self.shake_x = lerp(self.shake_x, 0 ,dt*self.shake_falloff)
        end

    	end

    	self.top = self.follow_y - (self.port_height/2)
    	self.bottom = self.follow_y + (self.port_height/2)
        
		-- move the camera
		local wx = love.graphics.getWidth()/2
		local wy = love.graphics.getHeight()/2
		local drag_offx, drag_offy = 0, 0
		if (View.global_drag_enable or self.draggable) then
			drag_offx, drag_offy = self.drag_offset_x, self.drag_offset_y
		end

		if self.noclip or (mouse_x > self.port_x and mouse_y > self.port_y and
		   mouse_x < self.port_x+self.port_width and mouse_y < self.port_y+self.port_height) then
			BlankE._mouse_x, BlankE._mouse_y = self:mousePosition()
			if self.follow_entity then
				BlankE._mouse_x = BlankE._mouse_x
				BlankE._mouse_y = BlankE._mouse_y
			else
				BlankE._mouse_x = BlankE._mouse_x - self.follow_x + (self.port_width/2)
				BlankE._mouse_y = BlankE._mouse_y - self.follow_y + (self.port_height/2)
			end
			BlankE._mouse_updated = true
		end

		self.camera:lockWindow(self.follow_x + self.offset_x + drag_offx + shake_x, self.follow_y + self.offset_y + drag_offy + shake_y, wx-self.max_distance, wx+self.max_distance,  wy-self.max_distance, wy+self.max_distance, self._smoother)
		if self._is_drawing > 0 then 
			self._is_drawing = self._is_drawing - 1
		end
	end,

	attach = function(self) 
		if self.camera and not self.disabled then  	 
	        self._is_drawing = 2
	        self.camera:attach(self.port_x, self.port_y, self.port_width, self.port_height, self.noclip)
		end

        if (BlankE._ide_mode or self._enable_grid) and not self.disabled then
        	local grid_width, grid_height = self.port_width, self.port_height
        	if self.noclip then
        		grid_width, grid_height = game_width, game_height
        	end

        	if (View.global_drag_enable or self.draggable) then
	        	BlankE._drawGrid(self.follow_x + self.offset_x + self.drag_offset_x, self.follow_y + self.offset_y + self.drag_offset_y, grid_width, grid_height)
	        else
	        	BlankE._drawGrid(self.follow_x + self.offset_x, self.follow_y + self.offset_y, grid_width, grid_height)
	        end
		end
    end,

	detach = function(self)
		if self.camera and not self.disabled then
			self.camera:detach()
			--love.graphics.pop()
			--love.graphics.setScissor(self._sx,self._sy,self._sw,self._sh)
		end
	end,

	draw = function(self, draw_func)
		self:attach()
		draw_func()
		self:detach()
	end
}

return View