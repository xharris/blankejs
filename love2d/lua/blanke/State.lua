local anim_tick = 0
local anim_end = 60
local anim_speed = 100
local big_size = 0
local transitioning = false
local anim_type = ''
local prev_state = ''
local transition_queue = {}

StateManager = {
	_stack = {},
	_callbacks = {'update','draw'},

	iterateStateStack = function(func, ...)

		for s, state in ipairs(StateManager._stack) do
			local bg_color = ifndef(state.background_color, Draw.background_color)
			if bg_color then
				Draw.setColor(bg_color)
				Draw.rect('fill', 0,0,game_width,game_height)
				Draw.resetColor()
			end

			local enter = "greater"
			local exit = "equal"

			if func == 'draw' and state._transitioning then	
				if anim_type == 'circle-out' then
					love.graphics.stencil(function()
				   		love.graphics.circle("fill", game_width / 2, game_height /2, lerp(0, big_size, anim_tick / anim_end))
					end, "replace", 1)
				end

				if anim_type == 'circle-in' then
					love.graphics.stencil(function()
				   		love.graphics.circle("fill", game_width / 2, game_height /2, big_size - lerp(0, big_size, anim_tick / anim_end))
					end, "replace", 1)
					enter = "equal"
					exit = "greater"
				end

				-- draw state being entered
				love.graphics.setStencilTest(enter, 0)
				state:draw()

				-- draw state being left
				local other_state = state._other_state
				love.graphics.setStencilTest(exit, 0)
				other_state:draw()

				love.graphics.setStencilTest()

			elseif state[func] ~= nil and (not state._off or not (func == 'update' and state._transitioning)) then
				state[func](...)
			end
		end

		-- update
		if func == 'update' and transitioning then
			local dt = ...

			if anim_tick > anim_end then
				anim_type = ''
				anim_tick = 0
				big_size = 0

				local curr_state = StateManager.current()
				curr_state._transitioning = false
				transitioning = false
				-- StateManager.pop(curr_state.classname)

				if #transition_queue > 0 then
					local next_transition = table.remove(transition_queue)
					State.transition(next_transition[1], next_transition[2])
				end
			else
				anim_tick = anim_tick + anim_speed * dt
			end
		end
	end,

	clearStack = function()
		for s, state in pairs(StateManager._stack) do
			state:_leave()
			StateManager._stack[s] = nil
		end
		StateManager._stack = {}
	end,

	push = function(new_state)
		new_state = StateManager.verifyState(new_state)
		new_state._off = false
		table.insert(StateManager._stack, new_state)
		if new_state.load and not new_state._loaded then
			new_state:load()
			new_state._loaded = true
		end
		if new_state.enter then new_state:enter() end
	end,

	-- remove newest state
	pop = function(state_name)
		local state = nil
		local index = 1
		if state_name then
			for s, obj_state in ipairs(StateManager._stack[#StateManager._stack]) do
				if obj_state.classname == state_name then
					index = s
					state = obj_state
				end
			end
		else
			state = StateManager._stack[#StateManager._stack]
		end

		state._transitioning = false
		state:_leave()

		table.remove(StateManager._stack, index)
	end,

	verifyState = function(state)
		local obj_state = state
		if type(state) == 'string' then 
			if _G[state] then obj_state = _G[state] else
				error('State \"'..state..'\" does not exist')
			end
		end
		return state
	end,

	switch = function(name)
		prev_state = State.current().classname

		-- verify state name
		local new_state = StateManager.verifyState(name)

		-- add to state stack
		StateManager.clearStack()
		if new_state then
			table.insert(StateManager._stack, new_state)
			if new_state.load and not new_state._loaded then
				new_state:load()
				new_state._loaded = true
			end
			new_state:_enter()
		end
	end,

	transition = function(next_state, animation)
		if not next_state._transitioning and not transitioning then
			anim_type = animation
			local curr_state = State.current()

			transitioning = true
			next_state._transitioning = true
			next_state._other_state = curr_state

			anim_tick = 0

			if anim_type == "circle-out" or anim_type == "circle-in" then
				big_size = math.sqrt((game_width*game_width) + (game_height*game_height))
			end

			prev_state = curr_state.classname
			StateManager.switch(next_state)
		else
			table.insert(transition_queue, 1, {next_state, animation})
		end
	end,

	current = function()
		if #StateManager._stack == 1 then
			return StateManager._stack[#StateManager._stack]
		else
			return StateManager._stack
		end
	end
}

State = Class{
	transition = function(...)
		StateManager.transition(...)
	end,

	switch = function(name)
		StateManager.switch(name)
	end,

	current = function()
		return StateManager.current()
	end,

	_enter = function(self)
		if self.enter then self:enter(prev_state) end
		self._off = false
	end,

	_leave = function(self)
		if self.leave then self:leave() end
		BlankE.clearObjects(false)
		self._off = true
	end
}

return State