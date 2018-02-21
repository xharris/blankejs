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

function clamp(x, min, max)
	if x < min then return min end
	if x > max then return max end
	return x
end

function lerp(a,b,amt)
	return a + (b-a) * amt
end

function ifndef(var_check, default)
	if var_check ~= nil then
		return var_check
	end
	return default
end

function randRange(n1, n2)
	return love.math.random(n1, n2)
end

function sinusoidal(min, max, speed, start_offset)
	local dist = (max - min)/2
	local offset = (min + max)/2
	local start = ifndef(start_offset, min) * (2*math.pi)
	return (100*math.sin(game_time * speed * math.pi + start)/100) * dist + offset;
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

function bitmask4(t, tile_val, x, y)
	function checkTile(x2, y2)
		if x2 > 0 and y2 > 0 and y2 <= #t and x2 <= #t[y2] and t[y2][x2] == tile_val then
			return 1
		end
		return 0
	end

	local result = 
		   1*checkTile(x,y-1) + 
		   2*checkTile(x-1,y) +
		   4*checkTile(x+1,y) +
		   8*checkTile(x,y+1)
		   
	return result
end

function bitmask8(t, tile_val, x, y)
	function checkTile(x, y)
		if x > 0 and y > 0 and x <= #t and y <= #t[x] and t[x][y] == tile_val then
			return 1
		end
		return 0
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
	return string.match(self, str)
end
function string:trim()
	return self:gsub("^%s+", ""):gsub("%s+$", "")
end
function string:at(num)
	return self:sub(num,num)
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
	return 0
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

function table.len(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

function table.forEach(t, func)
	local table_len = #t
	if table_len == 0 then table_len = table.len(t) end
	
	for i=1,table_len do
		func(i,t[i])
	end
end

function table.random(t)
	local len = table.len(t)
	local x = randRange(1, len)
	local i = 1
	for key,val in pairs(t) do
		if i == x then return val end
		i = i + 1
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