Signal = {
	registry = {},
	disabled = {},
	state_ref = {},

	emit = function(name, ...)
		local functions = ifndef(Signal.registry[name], {})

		if not Signal.disabled[name] then
			for f, func in ipairs(functions) do
				-- destroy the signal listeners if true is returned
				if func(...) == true then
					Signal.registry[name][f] = nil
				end
			end
		end
	end,

	_clean = function(state_name)
		if Signal.state_ref[state_name] then 
			for s, info in ipairs(Signal.state_ref[state_name]) do 
				Signal.registry[info[1]][info[2]] = nil
			end
		end
	end,

	on = function(name, func, persistent)
		Signal.disabled[name] = ifndef(Signal.disabled[name], false)
		Signal.registry[name] = ifndef(Signal.registry[name], {})

		table.insert(Signal.registry[name], func)

		if not persistent then
			local state = StateManager.current().classname
			if not Signal.state_ref[state] then
				Signal.state_ref[state] = {}
			end
			table.insert(Signal.state_ref[state], {name, #Signal.registry[name]})
		end
	end,

	enable = function(name)
		Signal.disabled[name] = false
	end,

	disable = function(name)
		Signal.disabled[name] = true
	end,
}

return Signal