Asset = Class{
	image_ext = {'tif','tiff','gif','jpeg','jpg','jif','jiff','jp2','jpx','j2k','j2c','fpx','png','pcd','pdf'},
	audio_ext = {'pcm','wav','aiff','mp3','aac','ogg','wma','flac','alac','wma'},
	font_ext = {'ttf','ttc','cff','woff','otf','otc','pfa','pfb','fnt','bdf','pfr'},
	info = {},
	paths_used = {},

	load = function()
		Asset.add('assets', nil, true)
		Asset.add('scenes', nil, true)
		Asset.add('scripts', nil, true)
		Asset.loadScripts()
	end,

	loadScripts = function()
		if Asset.info['script'] then
			for a, asset in pairs(Asset.info['script']) do
				if asset.category == 'script' then
					if BlankE._ide_mode then 
						result, chunk = xpcall(asset.object, debug.traceback)
						if not result then
							BlankE.errorhandler(chunk)
							--error(chunk)
						end
					else 
						require(string.gsub(asset.path,'%..+',''))
					end 
				end
			end
		end
	end,

	list = function(asset_type, prefix)
		local ret_table = {}

		for name, info in pairs(Asset.info[asset_type]) do
			if prefix then
				if name:starts(prefix..'/') then
					table.insert(ret_table, name:sub(#(prefix..'/')+1))
				end
			else
				table.insert(ret_table, name)
			end
		end

		return ret_table
	end,

	isPathAdded = function(path, prefix)
		if not prefix then
			return Asset.paths_used[path]
		else
			return Asset.paths_used[path..prefix]
		end
	end,

	add = function(path, prefix, no_duplicate)
		path = cleanPath(path)

		-- TODO: not working as intended (for efficiency)
		-- if table.hasValue(Asset.paths_used, path) then return end
		if no_duplicate and Asset.isPathAdded(path, prefix) then return end

		if not prefix then
			Asset.paths_used[path] = true
		else
			Asset.paths_used[path..prefix] = true
		end

		-- FOLDER
		local file_info = getFileInfo(path)
		if path:ends('/') or (file_info and file_info.type == "directory") then
			local files = love.filesystem.getDirectoryItems(path:sub(0,-1))
			for f, file in ipairs(files) do
				Asset.add(path..'/'..file, prefix)
			end
			return
		end

		if prefix then prefix = prefix..'/' else prefix = '' end
		
		local asset_ext = extname(path)
		local asset_name = ''
		if asset_ext then 
			asset_name = prefix..basename(path):gsub('.'..asset_ext,'')
		else
			asset_name = prefix..basename(path)
		end

		function acceptAsset(type_name, obj)
			Asset.info[type_name] = ifndef(Asset.info[type_name], {})
			Asset.info[type_name][asset_name] = {
				path = path,
				category = type_name,
				object = obj
			}
			return Asset.get(type_name, asset_name)
		end

		-- SCRIPT
		if path:ends('.lua') then
			local result, chunk
			if BlankE._ide_mode then 
				result, chunk = BlankE.try(love.filesystem.load, path)
			end
			return acceptAsset("script", chunk)
		
		-- IMAGE
		elseif table.hasValue(Asset.image_ext, asset_ext) then
			local image = love.graphics.newImage(path)
			if image then 
				local ret = acceptAsset("image", image) 
				Asset.info["image"][asset_name].image_data = love.image.newImageData(path)
				return ret
			end

		-- AUDIO
		elseif table.hasValue(Asset.audio_ext, asset_ext) then
			local audio_type = "static"
			if BlankE.settings.audio and BlankE.settings.audio[path] then
				audio_type = BlankE.settings.audio[path].type
			end
			local audio = love.audio.newSource(path,audio_type)
			if audio:getDuration() > 10 then audio = love.audio.newSource(path,"stream") end
			if audio then return acceptAsset("audio",audio) end

		-- MAP
		elseif path:ends('.map') then
			return acceptAsset("map", Map():load(love.filesystem.read(path)))

		-- SCENE
		elseif path:ends('.scene') then
			local scene_data = json.decode(love.filesystem.read(path))
			if scene_data then return acceptAsset("scene", scene_data ) end

		-- FONT
		elseif table.hasValue(Asset.font_ext, asset_ext) then
			return acceptAsset("font", path)


		-- FILE (etc)
		else
			return acceptAsset("file", love.filesystem.read(path))
		end
	end,

	has = function(category, name)
		return (Asset.info[category] and Asset.info[category][name])
	end,

	getInfo = function(category, name)
		if Asset.has(category, name) then
			return Asset.info[category][name]
		end
	end,

	get = function(category, name)
		if Asset.has(category, name) then
			if not Asset.info[category][name] then
				name = Asset.getNameFromPath(category, name)
			end
			return Asset.info[category][name].object
		end
	end,

	getNameFromPath = function(category, path)
		path = cleanPath(path)
		for name, info in pairs(Asset.info[category]) do
			if info.path == path then
				return name
			end
		end
		return path
	end,

	image = function(name) return Asset.get('image', name) end,
	audio = function(name) return Asset.get('audio', name) end,
	script = function(name) return Asset.get('script', name) end,
	map = function(name) return Asset.get('map', name) end,
	scene = function(name) return Asset.get('scene', name) end,
	font = function(name) return Asset.get('font', name) end,
	file = function(name) return Asset.get('file', name) end
}

return Asset