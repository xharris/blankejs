Signal = {
	registry = {},
	disabled = {},
	destroy = {},

	emit = function(name, ...)
		local functions = ifndef(Signal.registry[name], {})

		if not Signal.disabled[name] then
			for f, func in ipairs(functions) do
				func(...)
				if Signal.destroy[name] then
					for f2, func2 in ipairs(Signal.destroy[name]) do
						if func == func2 then
							Signal.registry[name][f] = nil
							Signal.destroy[name][f] = nil
						end
					end
				end
			end
		end
	end,

	on = function(name, func, destroy_on_call)
		Signal.disabled[name] = ifndef(Signal.disabled[name], false)
		Signal.registry[name] = ifndef(Signal.registry[name], {})

		table.insert(Signal.registry[name], func)
		if destroy_on_call then
			Signal.destroy[name] = ifndef(Signal.destroy[name], {})
			table.insert(Signal.destroy[name], func)
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