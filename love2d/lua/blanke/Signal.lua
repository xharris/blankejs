Signal = {
	registry = {},
	disabled = {},

	emit = function(name, ...)
		local functions = ifndef(Signal.registry[name], {})

		if not Signal.disabled[name] then
			for f, func in ipairs(functions) do
				func(...)
			end
		end
	end,

	on = function(name, func)
		Signal.disabled[name] = ifndef(Signal.disabled[name], false)
		Signal.registry[name] = ifndef(Signal.registry[name], {})

		table.insert(Signal.registry[name], func)
	end,

	enable = function(name)
		Signal.disabled[name] = false
	end,

	disable = function(name)
		Signal.disabled[name] = true
	end,
}

return Signal