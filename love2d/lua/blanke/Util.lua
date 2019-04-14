--[[
local sin = math.sin
local pi = math.pi
]]
function hex2rgb(hex)
	assert(type(hex) == "string", "hex2rgb: expected string, got "..type(hex).." ("..hex..")")
    hex = hex:gsub("#","")
    if(string.len(hex) == 3) then
        return {tonumber("0x"..hex:sub(1,1)) * 17, tonumber("0x"..hex:sub(2,2)) * 17, tonumber("0x"..hex:sub(3,3)) * 17}
    elseif(string.len(hex) == 6) then
        return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}
    end
end

-- modified version of https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
-- https://gist.github.com/raingloom/3cb614b4e02e9ad52c383dcaa326a25a
function hsv2rgb(hsv)
	local h, s, v = unpack(hsv)
	local a = 255
	if hsv[4] ~= nil then a = hsv[4] end

	s = s/100
	v = v/100

	local c = v * s
	local x = c * (1 - math.abs(h / 60 % 2 - 1))
	local m = v - c

	local value_table = {
		{c, x, 0}, {x, c, 0}, {0, c, x},
		{0, x, c}, {x, 0, c}, {c, 0, x}
	}

	for i, rgb in ipairs(value_table) do
		if h >= (i-1)*60 and h < (i)*60 then
			local r, g, b = unpack(rgb)
			return {(r + m) * 255, (g + m) * 255, (b + m) * 255, a}
		end
	end

	return {0, 0, 0, a}
end

function clamp(x, min, max)
	if x < min then return min end
	if x > max then return max end
	return x
end

function lerp(a,b,amt)
	return a + amt * (b-a)
end

function ifndef(var_check, default)
	if var_check ~= nil then
		return var_check
	end
	return default
end

function cond(condition, yes, no)
	if condition then return yes else return no end
end

-- both inclusive
function randRange(...)
	local ranges = {...}
	local r = love.math.random(1,ranges.length) -- choose a range to use (if there are multiple)
	if r % 2 == 0 then
		r = r - 1
	end
	if ranges[r] < ranges[r+1] then
		return love.math.random(ranges[r]*100, ranges[r+1]*100)/100
	else 
		return love.math.random(ranges[r+1]*100, ranges[r]*100)/100
	end
end

-- gets or sets random seed
function randSeed(seed_low, seed_high)
	if seed_low ~= nil then love.math.setRandomSeed(seed_low, seed_high) else
	return love.math.getRandomSeed() end
end

-- start_offset : percentage
function sinusoidal(min, max, speed, start_offset)
	local radius = (max - min)/2
	return min + -math.cos(lerp(0,math.pi/2,start_offset or 0) + game_time * speed) * radius + (radius)
end

function direction_x(angle, dist)
	return math.cos(math.rad(angle)) * dist
end

function direction_y(angle, dist)
	return math.sin(math.rad(angle)) * dist
end

function distance(x1,y1,x2,y2)
	return math.sqrt((x2-x1)^2+(y2-y1)^2)
end

function direction(x1,y1,x2,y2)
	return math.deg(math.atan2(y2-y1,x2-x1))
end

love.graphics.resetColor = function()
	love.graphics.setColor(255, 255, 255, 255)
end

-- https://github.com/Donearm/scripts
function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end
function dirname(str)
	if str:match(".-/.-") then
		local name = string.gsub(str, "(.*/)(.*)", "%1")
		return name
	else
		return ''
	end
end
function extname(str)
	str = str:match("^.+(%..+)$")
	if str then
		return str:sub(2)
	end
end

function cleanPath(path)
	if path then return path:gsub("[\\/]+","/") else return path end
end

local _ftypes = {}
function getFileInfo(path)
	if love.filesystem.getInfo then
		return love.filesystem.getInfo(path)
	else
		if not love.filesystem.exists(path) then return nil end
		local ftype = _ftypes[path]
		if not ftype then
			if love.filesystem.isDirectory(path) then ftype = "directory"
			elseif love.filsystem.isFile(path) then ftype = "file"
			elseif love.filesystem.isSymlink(path) then ftype = "symlink"
			else ftype = "other" end
		end
		return {
			type=ftype,
			size=love.filesystem.getSize(path),
			modtime=love.filesystem.getLastModified(path)
		}
	end
end

function bitmask4(tile_map, tile_val, x, y)
	local tile_vals = {}
	if type(tile_val) == "string" then table.insert(tile_vals, tile_val)
	else tile_vals = tile_val end

	function checkTile(x2, y2)
		return table.forEach(tile_vals, function(t, tile)
			if tile_map[x2] and tile_map[x2][y2] == tile then
				return 1
			end
		end) or 0
	end

	local result = 
		   1*checkTile(x,y-1) + 
		   2*checkTile(x-1,y) +
		   4*checkTile(x+1,y) +
		   8*checkTile(x,y+1)
		   
	return result
end

function bitmask8(tile_map, tile_val, x, y)
	local tile_vals = {}
	if type(tile_val) == "string" then table.insert(tile_vals, tile_val)
	else tile_vals = tile_val end

	function checkTile(x2, y2)
		return table.forEach(tile_vals, function(t, tile)
			if x2 > 0 and y2 > 0 and y2 <= #tile_map and x2 <= #tile_map[y2] and tile_map[y2][x2] == tile then
				return 1
			end
		end) or 0
	end

	local result = 1*checkTile(x-1,y-1) + 
		   2*checkTile(x-1,y) +
		   4*checkTile(x+1,y+1) +
		   8*checkTile(x-1,y) +
		   16*checkTile(x+1,y) +
		   32*checkTile(x+1,y-1) +
		   64*checkTile(x,y+1) +
		   128*checkTile(x+1,y+1)
	return result
end

--[[

	STRING

]]

function string:replaceAt(pos, r) 
	return table.concat{self:sub(1,pos-1),r,self:sub(pos+1)}
end

function string:starts(Start)
    return string.sub(self,1,string.len(Start))==Start
end
string.startsWith = string.starts

function string:ends(End)
	return string.sub(self,-string.len(End))==End
end
string.endsWith = string.ends
function string:split(sep)
	if sep == nil or sep == '' then
		local t = {}
		for i=1, #self do t[i]=self:sub(i,i) end
		return t
	else
		local sep, fields = sep or ":", {}
		local pattern = string.format("([^%s]+)", sep)
		self:gsub(pattern, function(c) fields[#fields+1] = c end)
		return fields
	end
end
function string:contains(str)
	return (string.match(self, str) ~= nil)
end
function string:trim()
	return self:gsub("^%s+", ""):gsub("%s+$", "")
end
function string:at(num)
	return self:sub(num,num)
end
function string:count(str)
	return select(2, string.gsub(self, str, ""))
end

--[[

	TABLE

]]
function table.find(t, value)
	for v, val in pairs(t) do
		if val == value then
			return v
		end
	end
	return nil
end	

function table.hasValue(t, value)
	for v, val in ipairs(t) do
		if val == value then return true end
	end
	return false
end

function table.copy(t)
	return {unpack(t)}
end

function table.deepcopy(t, fn_key)
	if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    local ret
    for k, v in pairs(t) do
        if type(v) == "table" then
        	if fn_key then
        		ret = fn_key(k, v)
        		if ret ~= nil then target[k] = ret else target[k] = table.deepcopy(v) end
        	else
            	target[k] = table.deepcopy(v)
        	end
        else
        	if fn_key then
        		ret = fn_key(k, v)
        		if ret ~= nil then v = ret end
        	end
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end

function table.toNumber(t)
	for i, val in ipairs(t) do
		t[i] = tonumber(val)
	end
	return t
end

function table.toString(t)
	for i, val in ipairs(t) do
		t[i] = tostring(val)
	end
	return t
end

function table.forEach(t, func)
	local table_len = #t
	if table_len == 0 then table_len = #t end
	
	for i=1,table_len do
		local ret_val = func(i,t[i])
		if ret_val then return ret_val end
	end
end

function table.random(t)
	local x = randRange(1, #t)
	local i = 1
	for key,val in pairs(t) do
		if i == x then return val end
		i = i + 1
	end
end

function table.keys(t)
	local ret = {}
	for k, v in pairs(t) do table.insert(ret, k) end
	return ret
end

function table.len(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

table.join = table.concat

function map2Dindex(x, y, columns)
	return (y-1) * columns + x
end

function map2Dcoords(i, columns)
	i = i - 1
	return i % columns + 1, math.floor(i / columns) + 1
end

--[[
function table.remove(t, value)
	for k, v in pairs(t) do
		if v == value then t[k] = nil end
	end
	return t
end]]

-- from https://stackoverflow.com/a/33296534
--[[ still unsure if this works
function table.merge(...)
	local concat_2tables = function(table1, table2)
	    len = #table1
	    for key, val in pairs(table2)do
	        table1[key+len] = val
	    end
	    return table1
	end

	local tableList = arg
    if tableList==nil then
        return  nil
    elseif #tableList == 1 then
        return  tableList[1]
    else
        table1 = tableList[1]
        restTableList = {unpack(tableList, 2)}
        return concat_2tables(table1, table.merge(restTableList))
    end
end]]

function table.merge(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

-- puts all keys/values from new into old
function table.update(old, new)
	if type(old) == "table" and type(new) == "table" then
		for k, v in pairs(new) do
			if type(k) ~= "string" and type(v) == "table" then
				table.update(old[k], new[k])
			else
				old[k] = v
			end
		end
	end
end

--[[

	MATH

]]
--[[--http://lua-users.org/wiki/SimpleRound
function math.sign(v)
	return (v >= 0 and 1) or -1
end
function math.round(v, bracket) -- example: math.round(120.68, 0.1) = 120.7
	bracket = bracket or 1
	return math.floor(v/bracket + math.sign(v) * 0.5) * bracket
end
]]
function math.round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end
function decimal_places(num)
	after_dec = tostring(num):split(".")
	if #after_dec == 2 then
		return after_dec[2]:len()	
	end
	return 0
end

function math.sign(val)
	if val < 0 then return -1 else return 1 end
end