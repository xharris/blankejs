Timer = Class{
	init = function(self, duration)
		self._before = {}					-- when Timer.start is called
		self._every = {}					-- every x seconds while timer is running
		self._after = {}					-- when the timer is over 
		self.time = 0						-- seconds
		self.countdown = ifndef(duration,0) -- for display purposes
		self.duration = ifndef(duration,0)	-- seconds
		self.disable_on_all_called = true	-- disable the timer when all functions are called (before, after)

		self.iterations = 0
		self.running = false
		self._running = false
		self._last_time = 0

		_addGameObject('timer', self)
		return self
	end,

	-- BEFORE, EVERY, AFTER: add functions
	before = function(self, delay, func)
		if func == nil then func = delay; delay = nil end
		table.insert(self._before,{
			func=func,
			delay=ifndef(delay,0),
			decimal_places=decimal_places(ifndef(delay,0)),
			called=0,
		})
		return self
	end,

	every = function(self, interval, func)
		if func == nil then func = interval; interval = nil end
		table.insert(self._every,{
			func=func,
			interval=ifndef(interval,1),
			decimal_places=decimal_places(ifndef(interval,0)),
			last_time_ran=0
		})
		return self
	end,

	after = function(self, delay, func)
		if func == nil then func = delay; delay = nil end
		table.insert(self._after,{
			func=func,
			delay=ifndef(delay,0),
			decimal_places=decimal_places(ifndef(delay,0)),
			called=0
		})
		return self
	end,
	-- END add functions

	update = function(self, dt)
		local all_called = true
		if self._running then
			-- call BEFORE
			for b, before in ipairs(self._before) do
				if not before.called then all_called = false end
				if not before.called and self.time >= before.delay then
					before.func(self.time)
					before.called = before.called + 1
				end
			end

			self.time = self.time + (love.timer.getTime() - self._last_time)
			self.countdown = self.duration - self.time
			self._last_time = love.timer.getTime()

			-- call EVERY
			if self.duration == 0 or self.time <= self.duration then
				for e, every in ipairs(self._every) do
					local fl_time = math.round(self.time, every.decimal_places)
					if fl_time ~= 0 and fl_time % every.interval == 0 and every.last_time_ran ~= fl_time then
						every.func(self.time)
						every.last_time_ran = fl_time
					end
					all_called = false
				end
			end

			-- call AFTER
			for a, after in ipairs(self._after) do
				if after.called < self.iterations then all_called = false end
				if after.called < self.iterations and self.time >= self.duration+after.delay then
					after.func(self.time)
					after.called = after.called + 1
				end
			end

			if self.time >= self.duration then
				self.running = false
			end

			if all_called and not self.running and self.disable_on_all_called then
				self._running = false
			end
		end
		return self
	end,

	start = function(self)
		--if not self._running then
			self:reset()
			self.iterations = self.iterations + 1
			self._running = true
			self.running = true
			self._last_time = love.timer.getTime()
		--end
		return self
	end,

	reset = function(self)
		self.time = 0
		self.countdown = self.duration
		self.running = false
		self._running = false
		self._last_time = 0

		for e,every in ipairs(self._every) do
			every.last_time_ran = 0
		end
		return self
	end,

	stop = function(self) self:reset() end
}

return Timer