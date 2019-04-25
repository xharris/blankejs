--[[
Copyright (c) 2010-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local function include_helper(to, from, seen)
	if from == nil then
		return to
	elseif type(from) ~= 'table' then
		return from
	elseif seen[from] then
		return seen[from]
	end

	seen[from] = to
	for k,v in pairs(from) do
		k = include_helper({}, k, seen) -- keys might also be tables
		if to[k] == nil then
			to[k] = include_helper({}, v, seen)
		end
	end
	
    if to.on_include then to:on_include(to) end
    
	return to
end

-- deeply copies `other' into `class'. keys in `other' that are already
-- defined in `class' are omitted
local function include(class, other)
	return include_helper(class, other, {})
end

-- returns a deep copy of `other'
local function clone(other)
	return setmetatable(include({}, other), getmetatable(other))
end

local function new(class)
	-- mixins
	class = class or {}  -- class can be nil
	local inc = class.__includes or {}
	if getmetatable(inc) then inc = {inc} end

	for _, other in ipairs(inc) do
		if type(other) == "string" then
			other = _G[other]
		end
		include(class, other)
	end

	class.__index = class.__index 	or class
	class.init    = class.init    	or class[1] or function() end
	class.include = class.include 	or include
	class.clone   = class.clone   	or clone
	class.onPropSet = {}
	class.onPropGet = {}
	class._hiddenProps = {}
	-- calls all of the setters using their current values
	class._refreshMutators = function(self)
		for prop, fn in pairs(self.onPropSet) do
			self[prop] = self[prop]
		end
	end

	class.__newindex = function(c,k,v)
		if c.onPropSet[k] ~= nil then
			v = ifndef(c.onPropSet[k](c,v), v)
			c._hiddenProps[k] = v
			return
		end
		rawset(c,k,v)
	end

	-- constructor call
	return setmetatable(class, {__call = function(c, ...)
		local o = setmetatable({}, c)

		-- apply init properties
		if class._init_properties then
			for k, v in pairs(class._init_properties) do
				o[k] = v
			end
			class._init_properties = nil
		end

		if o._init then
			o:_init(...)
		end
		if o.init then
			local ret_val =	o:init(...)
			-- get default values for onPropSet variables
			for var, fn in pairs(o.onPropSet) do
				if o.onPropGet[var] then
					o._hiddenProps[var] = o.onPropGet[var]()
				end
			end

			if o._post_init then
				o:_post_init(...)
			end

			if ret_val then return ret_val end
		end
	    
	    return o
	end,
	__index = function(c,k)
		local hidden_props = rawget(c, '_hiddenProps')
		local prop_get = rawget(c,'onPropGet')
    	if hidden_props and hidden_props[k] ~= nil then
    		return hidden_props[k]
    	end
		if prop_get and prop_get[k] then
			return prop_get[k](c)
		end
    	return rawget(class, k)
 	end})
end

-- interface for cross class-system compatibility (see https://github.com/bartbes/Class-Commons).
if class_commons ~= false and not common then
	common = {}
	function common.class(name, prototype, parent)
		return new{__includes = {prototype, parent}}
	end
	function common.instance(class, ...)
		return class(...)
	end
end


-- the module
return setmetatable({new = new, include = include, clone = clone},
	{__call = function(_,...) return new(...) end})
