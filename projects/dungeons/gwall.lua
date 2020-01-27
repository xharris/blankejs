GWall = class {
	dir='', -- left/right/up/down
	is_door=false,
	is_unlocked=false,
	to_outside=false, -- does this wall lead to the outside of the map?
	init = function(self, opt)
		table.update(self, opt)
	end,
	getFullString = function(self)
		local str = self.dir
		if self.is_door then str = str .. '.door.'..(self.is_unlocked and 'unlocked' or 'locked') end
		return str
	end,
	__ = {
		tostring = function(self)
			return self.dir
		end
	}
}