local _tweens = {}

Tween = Class{
	-- a: start value, b: change in value, d: duration of tween, dt: current time
	tween_func = {
		["linear"] = function(a, b, d, dt) return b*dt/d+a end,
		["quadratic in"] = function(a, b, d, dt) dt=dt/d; return b*dt*dt+a end,
		["quadratic out"] = function(a, b, d, dt) dt=dt/d; return -b*dt*(dt-2)+a end,
		["quadratic in/out"] = function(a, b, d, dt)
			dt = dt / d/2
			if (dt < 1) then return b/2*dt*dt+a end
			dt=dt-1	
			return -b/2*(dt*(dt-2)-1)+a
		end
	},

	init = function(self, var, value, duration, func_type)
		self.var = var
		self.value = value
		self.duration = duration
		self.type = ifndef(func_type, 'linear')

		-- get whether an object is changing or single var
		self._multival = false
		if type(value) == "table" then
			self._multival = true
		end

		-- get starting values
		self._start_val = self.value
		if self._multival then
			self._start_val = {}
			for key, value in pairs(self.value) do
				self._start_val[key] = self.var[key]
			end
		end

		self._go = false
		self._func = Tween.tween_func[self.type]
		self._dt = 0

		_addGameObject('tween', self)
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
			print(self._dt)
			if self._multival then
				for key, value in pairs(self.value) do
					local start_value = self._start_val[key]
					self.var[key] = self._func(start_value, value-start_value, self.duration, self._dt)
					-- finished?
					if (start_value < value and self.var[key] >= value) or (start_value > value and self.var[key] <= value) then
						self:_onFinish()
					end
				end
			else
				self.var = self._func(self._start_val, self.value-self._start_val, self.duration, self._dt)
				-- finished?
				if (self._start_val < self.value and self.var >= self.value) or (self._start_val > self.value and self.var <= self.value) then
					self:_onFinish()
				end
			end
		end
	end,

	play = function(self)
		self._go = true
	end,

	destroy = function(self)
		_destroyGameObject('tween',self)
	end,

	_onFinish = function(self) 
		self._go = false
		if self.onFinish then self:onFinish() end
	end
}

return Tween