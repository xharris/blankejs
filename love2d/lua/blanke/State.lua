local transition_queue = {}
local transition_obj = {}

local resetTransitionObj = function()
	if transition_obj.enter_state then
		transition_obj.enter_state.transitioning = false
		transition_obj.enter_state._has_transition = false
		transition_obj.enter_state._stencil_test = nil
	end
	if transition_obj.exit_state then
		transition_obj.exit_state.transitioning = false
		transition_obj.exit_state._has_transition = false
		transition_obj.exit_state._stencil_test = nil
	end
	Debug.log("resetting obj")
	if transition_obj.tween then transition_obj.tween:destroy() end

	transition_obj = {
		exit_state = nil,
		enter_state = nil,
		animation = '',
		stencil_fn = nil,
		tween = nil
	}
end
resetTransitionObj()

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

	iterateStateStack = function(func, ...)
		local transition_active = (transition_obj.enter_state and transition_obj.exit_state)

		for s, state in ipairs(StateManager._stack) do
			if not state._off then

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
		end
	end,

	clearStack = function()
		for s, state in ipairs(StateManager._stack) do
			state:_leave()
            StateManager._stack[s] = nil
		end
		StateManager._stack = {}
		StateManager.current_state = nil
	end,

	push = function(new_state)
		new_state = StateManager.verifyState(new_state)
        
        if new_state._off then
            new_state._off = false
            StateManager.current_state = new_state
            table.insert(StateManager._stack, new_state)
            if new_state.load and not new_state._loaded then
                new_state:load()
                new_state._loaded = true
            end
            if new_state.enter then new_state:enter() end
        end
	end,

	-- remove newest state
	pop = function(state_name)
		function closingStatements(state)
			state._has_transition = false
			state:_leave()
			state._off = true
		end

		if state_name then
			for s, obj_state in ipairs(StateManager._stack) do
				if obj_state.classname == state_name then
					closingStatements(obj_state)
					table.remove(StateManager._stack, s)
            		StateManager.current_state = StateManager._stack[#StateManager._stack]
				end
			end
		else
			local state = StateManager._stack[#StateManager._stack]
			closingStatements(state)
			table.remove(StateManager._stack)
            StateManager.current_state = StateManager._stack[#StateManager._stack]
		end
	end,

	states = {},
	verifyState = function(state)
		local obj_state = state
		if type(state) == 'string' then 
			if StateManager.states[state] then obj_state = StateManager.states[state] else
				error('State \"'..state..'\" does not exist')
			end
		end
		return obj_state
	end,

	switch = function(name)
		-- add to state stack
		StateManager.clearStack()
        if name ~= nil then
            StateManager.push(name)
        end
	end,

	_setupTransition = function(queue_info)
		local anim_type = queue_info[3]

		transition_obj.exit_state = queue_info[1]
		transition_obj.enter_state = queue_info[2]
		transition_obj.animation = anim_type
        
        transition_obj.exit_state.transitioning = true
        transition_obj.enter_state.transitioning = true

		local diag_size = math.sqrt((game_width*game_width) + (game_height*game_height))

		if anim_type == "circle-in" then
			transition_obj.stencil_fn = function()
				love.graphics.circle("fill", game_width / 2, game_height /2, transition_obj.tween.var)
			end
			transition_obj.tween = Tween(diag_size, 0, .5)
			transition_obj.enter_state._stencil_test = "equal"	
		end

		if anim_type == "circle-out" then
			transition_obj.stencil_fn = function()
				love.graphics.circle("fill", game_width / 2, game_height /2, transition_obj.tween.var)
			end
			transition_obj.tween = Tween(0, diag_size, .5)
			transition_obj.enter_state._stencil_test = "greater"
		end
	end,

	transition = function(next_state, animation)
		next_state = StateManager.verifyState(next_state)

		local curr_state = StateManager:current()
		if next_state and not curr_state._has_transition and not next_state._has_transition then
			Debug.log("adding",next_state.classname)
			curr_state._has_transition = true
			next_state._has_transition = true

			table.insert(transition_queue, 1, {curr_state, next_state, animation})
		end

		if transition_obj.tween and not transition_obj.tween:isRunning() then
			resetTransitionObj()
			Debug.log("queue size",#transition_queue)
		end

		-- no transitions happening at the moment
		if not transition_obj.tween and #transition_queue > 0 then
			StateManager._setupTransition(transition_queue[1])

			transition_obj.tween.onFinish = function()
				local exit_state = transition_obj.exit_state
				resetTransitionObj()
				StateManager.pop(exit_state.classname)
				table.remove(transition_queue)
				Debug.log("now in",StateManager.current().classname)
				Debug.log("--",#transition_queue, "left  --")
				StateManager.transition()
			end
			transition_obj.tween:play()
			StateManager.push(transition_obj.enter_state)

		end
	end,

    current_state = nil,
	current = function()
		return StateManager.current_state
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
		BlankE.clearObjects(false, self.classname)
		self._off = true
	end
}

return State