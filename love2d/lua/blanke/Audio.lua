Audio = Class{
	_sources = {},
	init = function(self, name)
		name = cleanPath(name)
		self.name = name 

		local asset = Asset.audio(name)

		if asset then
			self.audio = asset

		elseif love.filesystem.getInfo(name) then
			self.audio = Asset.add(name)

		end
		self.audio = self.audio:clone()

		-- add to list of similar sources
		if not Audio._sources[name] then Audio._sources[name] = {} end
		table.insert(Audio._sources[self.name], self)

		assert(self.audio, 'Audio not found: \"'..tostring(name)..'\"')
	
		self.onPropSet["pitch"] = function(self, v)
			self.audio:setPitch(v)
		end
	end,

	play = function(self) self.audio:play()	end,
	pause = function(self) self.audio:pause() end,
	stop = function(self) self.audio:stop() end,

	playAll = function(self, others_too)
		for s, src in ipairs(Audio._sources[self.name]) do
			src:play()
		end
		if others_too then
			for name, sources in pairs(Audio._sources) do
				for s, src in ipairs(sources) do
					src:play()
				end
			end
		end
	end,

	pauseAll = function(self, others_too)
		for s, src in ipairs(Audio._sources[self.name]) do
			src:pause()
		end
		if others_too then
			for name, sources in pairs(Audio._sources) do
				for s, src in ipairs(sources) do
					src:pause()
				end
			end
		end
	end,

	stopAll = function(self, others_too)
		for s, src in ipairs(Audio._sources[self.name]) do
			src:stop()
		end
		if others_too then
			for name, sources in pairs(Audio._sources) do
				for s, src in ipairs(sources) do
					src:stop()
				end
			end
		end
	end,
}

return Audio