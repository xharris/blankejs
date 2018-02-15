steamworks = nil

Steam = Class{
	appid = "480",
	_initialized = false,

	init = function()
		local file = io.open("steam_appid.txt")

		local file, err = io.open("steam_appid.txt", "w")
		if file then
			file:write(Steam.appid)
			io.close(file)
		else
			error("failed to write steam_appid.txt (because it's needed) in cd : " .. err)
		end

		if not Steam._initialized then
			Steam._initialized = true

			ffi = require('ffi')
			steamworks = blanke_require('extra.steamworks.steamworks')
		end
	end,
}

return Steam