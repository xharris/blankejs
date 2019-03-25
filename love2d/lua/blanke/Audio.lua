Audio = Class{
	setVolume = function(vol) love.audio.setVolume(vol) end,
	getVolume = function() love.audio.getVolume() end,
	setPosition = function(x,y,z) love.audio.setPosition(x,y,z) end, -- set position of listener

	init = function(self, name)
		name = cleanPath(name)
		self.name = name 
		self.sources = {}

		local asset = Asset.audio(name)

		if asset then
			self.audio = asset

		elseif getFileInfo(name) then
			self.audio = Asset.add(name)

		end
		self.audio = self.audio:clone()

		assert(self.audio, 'Audio not found: \"'..tostring(name)..'\"')
	
		self.onPropSet["pitch"] = function(self, v) self.audio:setPitch(v) end
		self.onPropSet["volume"] = function(self, v) self.audio:setVolume(v) end
		self.onPropSet["x"] = function(self, v) self.audio:setPosition(v,self.y,self.z) end
		self.onPropSet["y"] = function(self, v) self.audio:setPosition(self.x,v,self.z) end
		self.onPropSet["z"] = function(self, v) self.audio:setPosition(self.x,self.y,v) end

		self.onPropGet["seconds"] = function() return self.audio:tell("seconds") end
		self.onPropGet["x"] = function() return 0 end
		self.onPropGet["y"] = function() return 0 end
		self.onPropGet["z"] = function() return 0 end

		self.looping = false
		self.positional = true

    	_addGameObject('audio', self)
	end,

	play = function(self) self.audio:play()	end,
	pause = function(self) self.audio:pause() end,
	stop = function(self) self.audio:stop() end,

	play = function(self)
		self.audio:setRelative(self.positional)
		if self.looping then
			self.audio:setLooping(true)
			self.audio:play()
		else
			self.audio:setLooping(false)
			local new_src = self.audio:clone()
			new_src:play()
			table.insert(self.sources, new_src)
		end
	end,

	pause = function(self)
		self.pause:stop()
		for s, src in ipairs(self.sources) do
			src:pause()
		end
	end,

	stop = function(self)
		self.audio:stop()
		for s, src in ipairs(self.sources) do
			src:stop()
		end
	end,

	seek = function(self, ...)
		self.audio:seek(...)
	end
}

return Audio