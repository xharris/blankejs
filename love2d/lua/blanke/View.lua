View = Class{
	init = function(self, follow_entity)
		-- the final draw position
		self.x = 0
		self.y = 0

		self.port_width = game_width
		self.port_height = game_height

        self.follow_entity = follow_entity
        self.offset_x = 0
        self.offset_y = 0

        -- ways for camera to move towards x,y
        self.move_type = 'snap'
        -- lockX
        self.lock_x = 0

        self.angle = 0
        self.scale_x = 1
        self.scale_y = 1

        _addGameObject('view',self)
	end,

	zoom = function(self, x, y)
		y = ifndef(y, x)
		self.scale_x = x
		self.scale_y = y
	end,

	follow = function(self, entity)
		self.follow_entity = entity
	end,

	update = function(self, dt)
		local follow_x, follow_y = 0, 0
		if self.follow_entity then
			follow_x, follow_y = self.follow_entity.x, self.follow_entity.y
		end

		local target_x = follow_x + self.offset_x
		local target_y = follow_y + self.offset_y

		-- do transitional tween stuff

		self.x = target_x
		self.y = target_y
	end,

	attach = function(self)
		local half_w, half_h = self.port_width/2, self.port_height/2
		Draw.push('all')
		Draw.translate(math.floor(half_w), math.floor(half_h))
		Draw.scale(self.scale_x, self.scale_y)
		Draw.rotate(self.angle)
		Draw.translate(-math.floor(self.x), -math.floor(self.y))
	end,

	detach = function(self)
		Draw.pop()
	end,

	draw = function(self, fn)
		self:attach()
		fn()
		self:detach()
	end
}

return View