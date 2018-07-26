local transition_obj = {}

local resetTransitionObj = function()
	if transition_obj.enter_state then
		transition_obj.enter_state._stencil_test = nil
	end
	if transition_obj.exit_state then
		transition_obj.exit_state._stencil_test = nil
	end
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
	_in_transition = false,
	_stray_objects = {},

	iterateStateStack = function(func, ...)
		local transition_active = (transition_obj.enter_state and transition_obj.exit_state)

		-- update any stateless objects
		if func == 'update' then
			for cat, objects in pairs(StateManager._stray_objects) do
				for o, obj in ipairs(objects) do
					if obj[func] then obj[func](obj, ...) end
				end
			end
		end

		for s, state in ipairs(StateManager._stack) do
			if not state._off then

				if func == 'update' then
					for group, arr in pairs(state.game) do
				        for i_e, e in ipairs(arr) do
				            if e.auto_update and not e.pause then
				                if e._update then
				                	e:_update(...)
				                elseif e.update then
					                e:update(...)
					            end
				            end
				        end
				    end
				end

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

		if func == 'update' and transition_obj.tween then
			transition_obj.tween:update(...)
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

	push = function(new_state, prev_state)
		new_state = StateManager.verifyState(new_state)
		prev_state = ifndef(ifndef(prev_state, StateManager.current_state), {classname=''}).classname
        
        if new_state._off then
            new_state._off = false
            StateManager.current_state = new_state
            table.insert(StateManager._stack, new_state)
            if new_state.load and not new_state._loaded then
                new_state:load()
                new_state._loaded = true
            end
            if new_state.enter then new_state:enter(prev_state) end
        end
	end,

	-- remove newest state
	pop = function(state_name)
		function closingStatements(state)
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
		local current_state = StateManager.current_state
		-- add to state stack
		StateManager.clearStack()
        if name ~= nil then
            StateManager.push(name, current_state)
        end
	end,

	_setupTransition = function(curr_state, next_state, animation)

		transition_obj.exit_state = curr_state
		transition_obj.enter_state = next_state
		transition_obj.animation = animation
        
		local diag_size = math.sqrt((game_width*game_width) + (game_height*game_height))

		if animation == "circle-in" then
			transition_obj.stencil_fn = function()
				love.graphics.circle("fill", game_width / 2, game_height /2, transition_obj.tween.var)
			end
			transition_obj.tween = Tween(diag_size, 0, .5)
			transition_obj.enter_state._stencil_test = "equal"	
		end

		if animation == "circle-out" then
			transition_obj.stencil_fn = function()
				love.graphics.circle("fill", game_width / 2, game_height /2, transition_obj.tween.var)
			end
			transition_obj.tween = Tween(0, diag_size, .5)
			transition_obj.enter_state._stencil_test = "greater"
		end

		if animation == "wipe-up" or animation == "wipe-down" then
			transition_obj.stencil_fn = function()
				Draw.rect("fill", 0, transition_obj.tween.var, game_width, game_height - transition_obj.tween.var)
			end
			if animation == "wipe-up" then
				transition_obj.tween = Tween(game_width, 0, .5)
				transition_obj.enter_state._stencil_test = "greater"
			end
			if animation == "wipe-down" then
				transition_obj.tween = Tween(0, game_width, .5)
				transition_obj.enter_state._stencil_test = "equal"
			end
		end

		if animation == "clockwise" or animation == "counter-clockwise" then
			transition_obj.stencil_fn = function()
				love.graphics.arc("fill", game_width/2, game_height/2, diag_size, math.rad(270), math.rad(transition_obj.tween.var+270))
			end
			if animation == "clockwise" then
				transition_obj.tween = Tween(0, 360, .5)
				transition_obj.enter_state._stencil_test = "greater"
			end
			if animation == "counter-clockwise" then
				transition_obj.tween = Tween(360, 0, .5)
				transition_obj.enter_state._stencil_test = "equal"
			end
		end

		if transition_obj.tween then
			transition_obj.tween.auto_update = false
		end
	end,

	transition = function(next_state, animation)
		if not (transition_obj.enter_state or transition_obj.exit_state) then

			local curr_state = StateManager.current()
			next_state = StateManager.verifyState(next_state)

			resetTransitionObj()

			StateManager._setupTransition(curr_state, next_state, animation)

			transition_obj.tween.onFinish = function()
				local exit_state = transition_obj.exit_state
				resetTransitionObj()
				StateManager.pop(exit_state.classname)
				StateManager._in_transition = false
			end

			transition_obj.tween:play()
			StateManager._in_transition = true
			StateManager.push(transition_obj.enter_state)
		end
	end,

    current_state = nil,
	current = function()
		return StateManager.current_state
	end
}

State = Class{
	game = {},
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
		BlankE.clearObjects(true, self)
		self._off = true
	end
}

return State