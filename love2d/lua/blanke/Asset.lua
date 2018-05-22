Asset = Class{
	image_ext = {'tif','tiff','gif','jpeg','jpg','jif','jiff','jp2','jpx','j2k','j2c','fpx','png','pcd','pdf'},
	audio_ext = {'pcm','wav','aiff','mp3','aac','ogg','wma','flac','alac','wma'},
	info = {},

	loadScripts = function()
		if Asset.info['script'] then
			for a, asset in pairs(Asset.info['script']) do
				if asset.category == 'script' then
					result, chunk = pcall(asset.object)
					if not result then
						print(chunk)
						error(chunk)
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

	add = function(path, prefix)
		-- FOLDER
		if path:ends('/') then
			local files = love.filesystem.getDirectoryItems(path:sub(0,-1))
			for f, file in ipairs(files) do
				Asset.add(path..file, prefix)
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

		-- SCRIPT
		if path:ends('.lua') then
			Asset.info['script'] = ifndef(Asset.info['script'], {})

			local result, chunk = BlankE.try(love.filesystem.load, path)

			Asset.info['script'][asset_name] = {
				path = path,
				category = 'script',
				object = chunk
			}
			return Asset.get(asset_name)
		
		-- IMAGE
		elseif table.hasValue(Asset.image_ext, asset_ext) then
			Asset.info['image'] = ifndef(Asset.info['image'], {})
			
			local image = love.graphics.newImage(path)
			if image then
				Asset.info['image'][asset_name] = {
					path = path,
					category = 'image',
					object = image
				}
				return Asset.get(asset_name)
			end

		-- MAP
		elseif path:ends('.map') then
			Asset.info['map'] = ifndef(Asset.info['map'], {})
			
			Asset.info['map'][asset_name] = {
				path = path,
				category = extname(path),
				object = Map():load(love.filesystem.read(path))
			}
			return Asset.get(asset_name)
		
		-- FILE (etc)
		else
			Asset.info['file'] = ifndef(Asset.info['file'], {})
			
			Asset.info['file'][asset_name] = {
				path = path,
				category = extname(path),
				object = love.filesystem.read(path)
			}
			return Asset.get(asset_name)
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
			return Asset.info[category][name].object
		end
	end,

	image = function(name) return Asset.get('image', name) end,
	script = function(name) return Asset.get('script', name) end,
	map = function(name) return Asset.get('map', name) end,
	file = function(name) return Asset.get('file', name) end
}

return Asset