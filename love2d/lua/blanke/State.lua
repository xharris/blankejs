local transition_queue = {}
local transition_obj = {
	i = 0,
	exit_state = nil,
	enter_state = nil,
	animation = '',
	stencil_fn = nil,
	tween = nil
}

local drawStateNormal = function(state)
	local bg_color = ifndef(state.background_color, Draw.background_color)
	if bg_color then
		Draw.setColor(bg_color)
		Draw.rect('fill', 0,0,game_width,game_height)
		Draw.resetColor()
	end
	if state.draw then state:draw() end
end

local drawStateStencil = function(state)
	love.graphics.stencil(transition_obj.stencil_fn, "replace", 1)
	love.graphics.setStencilTest(state._stencil_test, 0)
	drawStateNormal(state)
	love.graphics.setStencilTest()
end

StateManager = {
	_stack = {},
	_callbacks = {'update','draw'},

	iterateStateStack = function(func, ...)
		local transition_active = (#transition_queue > 0)

		for s, state in ipairs(StateManager._stack) do
			if func == 'draw' and state.draw then
				-- is a transition happening?
				if transition_active then
					-- is this the 'entering' state?
					if transition_obj.enter_state.classname == state.classname then
						drawStateStencil(state)
					
					-- is this the 'exiting' state?
					elseif transition_obj.exit_state.classname == state.classname then
						drawStateStencil(state)

					else
						drawStateNormal(state)

					end
				else
					drawStateNormal(state)
				end
			else
				if state[func] then state[func](...) end
			end
		end
	end,

	clearStack = function()
		for s, state in ipairs(StateManager._stack) do
			state:_leave()
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
		Debug.log("push",new_state.classname)
	end,

	-- remove newest state
	pop = function(state_name)
		function closingStatements(state)
			Debug.log("pop",state.classname)
			state._has_transition = false
			state:_leave()
		end

		if state_name then
			for s, obj_state in ipairs(StateManager._stack) do
				if obj_state.classname == state_name then
					closingStatements(obj_state)
					table.remove(StateManager._stack, s)
				end
			end
		else
			local state = StateManager._stack[#StateManager._stack]
			closingStatements(state)
			table.remove(StateManager._stack)
		end
			Debug.log("state",#StateManager._stack)
	end,

	verifyState = function(state)
		local obj_state = state
		if type(state) == 'string' then 
			if _G[state] then obj_state = _G[state] else
				error('State \"'..state..'\" does not exist')
			end
		end
		return obj_state
	end,

	switch = function(name)
		-- add to state stack
		StateManager.clearStack()
		StateManager.push(name)
	end,

	_setupTransition = function(queue_info)
		local anim_type = queue_info[3]

		transition_obj.exit_state = queue_info[1]
		transition_obj.enter_state = queue_info[2]
		transition_obj.animation = anim_type

		local diag_size = math.sqrt((game_width*game_width) + (game_height*game_height))

		if anim_type == "circle-in" then
			transition_obj.stencil_fn = function()
				love.graphics.circle("fill", game_width / 2, game_height /2, transition_obj.i)
			end
			transition_obj.i = diag_size
			transition_obj.tween = Tween(transition_obj, {i = 0}, .5)
			transition_obj.enter_state._stencil_test = "greater"	
			transition_obj.enter_state._stencil_test = "equal"	
		end

		if anim_type == "circle-out" then
			transition_obj.stencil_fn = function()
				love.graphics.circle("fill", game_width / 2, game_height /2, transition_obj.i)
			end
			transition_obj.i = 0
			transition_obj.tween = Tween(transition_obj, {i = diag_size}, .5)
			transition_obj.enter_state._stencil_test = "equal"	
			transition_obj.enter_state._stencil_test = "greater"
		end
	end,

	transition = function(next_state, animation)
		next_state = StateManager.verifyState(next_state)

		local curr_state = StateManager:current()
		if not curr_state._has_transition then
			curr_state._has_transition = true

			if next_state then
				table.insert(transition_queue, 1, {curr_state, next_state, animation})
			end

			-- no transitions happening at the moment
			if transition_obj.tween == nil and #transition_queue > 0 then
				StateManager._setupTransition(table.remove(transition_queue))

				StateManager.push(transition_obj.enter_state)
				transition_obj.tween.onFinish = function()
					StateManager.pop(transition_obj.exit_state.classname)
					transition_obj.tween = nil
					Debug.log("queue len",#transition_queue)
					--StateManager.transition()
				end
				transition_obj.tween:play()
			end
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