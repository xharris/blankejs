# Props

```
mouse_x, mouse_y
game_width, game_height
window_width, window_height
game_time   -- time elapsed since game started
dt_mod      -- modifies game speed (default = 1)
```

# Methods

```
bool ifndef(var, default)       -- returns default if var is undefined. otherwise returns var
num[3] hex2rgb(hex)
num[3] hsv2rgb({h,s,v})			-- h: degrees, s: 0-100, v: 0-100

num decimal_places(num)			-- number of dec places in a number
num math.round(num, places)
num math.sign(num)              -- returns -1 and 1 for negative and positive respectively
num clamp(x, min, max)			-- inclusive
num lerp(a, b, amt)
num cond(condition, y, n)       -- similar to (condition ? y : n)
num randRange(min, max)
num randSeed([low, high])       -- sets/gets the random seed
num sinusoidal(min, max, speed, start_offset)
num round(num, places)
num direction_x(degrees, distance)
num direction_y(degrees, distance)
num direction(x1,y1,x2,y2)      -- returns angle (degrees) between two points /_

num bitmask4(map_table, tile_value(s), x, y)	-- https://gamedevelopment.tutsplus.com/tutorials/how-to-use-tile-bitmasking-to-auto-tile-your-level-layouts--cms-25673
num bitmask8(map_table, tile_value(s), x, y)	-- untested

str basename(str)
str dirname(str)
str extname(str)	    -- return extension (without period)
{} getFileInfo(path)    -- returns nil if the file doesnt exist. otherwise returns {type,size,modtime} where type can be "directory/file/symlink"

-- STRING (starts with 'my_string:')
replaceAt(pos, new_str)
starts(str)
ends(str)
split(sep_str)
contains(str)
trim()
at(num)

-- TABLE (starts with 'table.')
find(t, value)
hasValue(t, value)
copy(t)
deepcopy(t)
toString(t)             -- converts everything in table to string
toNumber(t)             -- converts everything in table to number
len(t)
forEach(t, func)		-- func(i,val). will return a value and end early if 'func' returns a value
random(t)
keys(t)
join(t, sep)
update(old, new)	    -- update values in old table with values in new table
merge(t1, t2)           -- appends values from t2 into t1

map2Dindex(x, y, columns)
map2Dcoords(i, columns)
```
