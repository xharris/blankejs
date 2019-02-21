
-- lone methods
bool ifndef(var, default)
num[3] hex2rgb(hex)
num[3] hsv2rgb({h,s,v})			-- h: degrees, s: 0-100, v: 0-100

num decimal_places(num)			-- number of dec places in float
num clamp(x, min, max)			-- inclusive
num lerp(a, b, amt)
num randRange(min, max)
num sinusoidal(min, max, speed, start_offset)
num round(num, places)
num direction_x(degrees, distance)
num direction_y(degrees, distance)

num bitmask4(map_table, tile_value(s), x, y)	-- https://gamedevelopment.tutsplus.com/tutorials/how-to-use-tile-bitmasking-to-auto-tile-your-level-layouts--cms-25673
num bitmask8(map_table, tile_value(s), x, y)	-- untested

str basename(str)
str dirname(str)
str extname(str)								-- return extension (without period)

-- STRING
replaceAt(pos, new_str)
starts(str)
ends(str)
split(sep_str)
contains(str)
trim()
at(num)

-- TABLE
find(t, value)
hasValue(t, value)
copy(t)
deepcopy(t)
toNumber(t)
len(t)
forEach(t, func)								-- will return a value and end early if 'func' returns a value
random(t)
keys(t)
join(t, sep)
update(old, new)								-- update values in old table with values in new table

map2Dindex(x, y, columns)
map2Dcoords(i, columns)
