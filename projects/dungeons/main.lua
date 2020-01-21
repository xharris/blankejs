local map = {}
local map_size = {1,1}
local tile_size = {16,16}
local room_type_info = {
	grass = {
		color='green'
	},
	cemetary = {
		color='gray',
	},
	forest = {
		color='indigo',
		w=6, h=6
	},
	house = {
		color='brown',
		w=4, h=4,
		doors=2
	}
}

Game{
	filter = "nearest",
	plugins = {'xhh-array'},
	load = function()
		-- check if a map is big enough
		do
			local total_size = map_size[1] * map_size[2]
			local total_type_size = 0
			for room_type, info in pairs(room_type_info) do
				info.w = info.w or 2
				info.h = info.h or 2
				total_type_size = total_type_size + info.w * info.h
			end
			total_type_size = total_type_size * 2
			local index = map_size[1] < map_size[2] and 1 or 2
			while total_type_size > total_size do
				map_size[index] = map_size[index] + 1
				total_size = map_size[1] * map_size[2]
				index = index == 1 and 2 or 1
			end
		end
		-- create rect grid
		for x = 1,map_size[1] do
			map[x] = {}
			for y = 1, map_size[2] do
				map[x][y] = {
					type='grass'
				}
			end
		end
		-- create random area types
		for room_type, info in pairs(room_type_info) do
			local taken = true
			-- find good location
			while taken do 
				taken = false
				local x, y = Math.random(1,map_size[1]), Math.random(1,map_size[2])
				for xcheck = x, x+info.w - 1 do
					for ycheck = y, y+info.h - 1 do
						if map[xcheck] and map[xcheck][ycheck] and map[xcheck][ycheck].type ~= "grass" then 
							taken = true
						end
					end
				end
				if not taken then 
					for xtake = x, x+info.w - 1 do
						if xtake > #map then 
							map[xtake] = {}			
							for y = 1, map_size[2] do
								map[xtake][y] = {
									type='grass'
								}
							end
						end
						for ytake = y, y+info.h - 1 do
							map[xtake][ytake] = {
								type = room_type	
							}
						end
					end
				end
			end
		end
		-- create doors
		for room_type, info in pairs(room_type_info) do
			if info.doors and info.doors > 0 then
				
			end
		end
	end,
	draw = function(d)
		for x, ytiles in ipairs(map) do	
			for y, tile in ipairs(ytiles) do
				Draw{
					{'lineWidth',2},
					{'color', room_type_info[tile.type].color},
					{'rect', 'fill', x * tile_size[1], y * tile_size[2], tile_size[1], tile_size[2]},
					{'color','white'},
					{'rect', 'line', x * tile_size[1], y * tile_size[2], tile_size[1], tile_size[2]}
				}
			end
		end
	end
}