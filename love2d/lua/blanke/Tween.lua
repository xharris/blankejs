local _tweens = {}

Tween = Class{
	-- a: start value, b: change in value, d: duration of tween, dt: current time
	-- t->dt, d->d, b->a, c->b
	tween_func = {
		["linear"] = function(a, b, d, dt) return b*dt/d+a end,
		["quadratic in"] = function(a, b, d, dt) dt=dt/d; return b*dt*dt+a end,
		["quadratic out"] = function(a, b, d, dt) dt=dt/d; return -b*dt*(dt-2)+a end,
		["quadratic in/out"] = function(a, b, d, dt)
			dt = dt / d/2
			if (dt < 1) then return b/2*dt*dt+a end
			dt=dt-1	
			return -b/2*(dt*(dt-2)-1)+a
		end,
		["circular in"] = function(a, b, d, dt) dt=dt/d; return -b*(math.sqrt(1-(dt*dt))-1)+a end
	},

	init = function(self, var, value, duration, func_type)
		self.var = var
		self.duration = ifndef(duration, 1)
		self.type = ifndef(func_type, 'linear')
		self.valid = true

		self:setValue(value)

		self._go = false
		self._func = Tween.tween_func[self.type]
		self._dt = 0

		self.persistent = true
		_addGameObject('tween', self)
	end,

	setValue = function(self, value)
		-- get whether an object is changing or single var
		self.value = value
		self._multival = false
		self._bezier = false
		if type(value) == "table" then
			if value.type and value.type == 'bezier' then
				self._bezier = value
			else
				self._multival = true
			end
		end
	end,

	addFunction = function(self, name, func)
		Tween.tween_func[name] = func
	end,

	setFunction = function(self, name)
		self.type = name
		self._func = Tween.tween_func[name]
	end,

	update = function(self, dt)
		if self._go then
			self._dt = self._dt + dt

			if self._multival then
				for key, value in pairs(self.value) do
					local start_value = self._start_val[key]
					self.var[key] = self._func(start_value, value-start_value, self.duration*1000, self._dt*1000)
					-- finished?
					if (start_value < value and self.var[key] >= value) or (start_value > value and self.var[key] <= value) then
						self:_onFinish()
					end
				end
			elseif self._bezier then
				self._start_val = self._func(self._start_val, 100-self._start_val, self.duration*1000, self._dt*1000)
				
				if math.ceil(self._start_val) >= 100 then self._start_val = 100 end
				if self._bezier:size() > 1 then
					local x, y = self._bezier:at((100-self._start_val)/100)
					if self.var.x then self.var.x = x end
					if self.var.y then self.var.y = y end
				end
				if self._start_val >= 100 then
					self:_onFinish()
				end
			else
				self.var = self._func(self._start_val, self.value-self._start_val, self.duration*1000, self._dt*1000)
				-- finished?
				if (self._start_val < self.value and self.var >= self.value) or (self._start_val > self.value and self.var <= self.value) then
					self:_onFinish()
				end
			end
		end
	end,

	play = function(self)
		self._go = true
		self._dt = 0

		-- get starting values
		self._start_val = self.var
		if self._bezier then
			self._start_val = 0
		end
		if self._multival then
			self._start_val = {}
			for key, value in pairs(self.value) do
				self._start_val[key] = self.var[key]
			end
		end
	end,

	isRunning = function(self)
		return (self._go and self._dt > 0)
	end,

	destroy = function(self)
		_destroyGameObject('tween',self)
	end,

	_onFinish = function(self) 
		self._go = false
		self._dt = 0
		if self.onFinish then self:onFinish() end
	end
}

return Tween