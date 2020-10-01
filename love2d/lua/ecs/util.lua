local tbl_to_str
tbl_to_str = function(t, str)
    local empty = true
    str = str or ''
    str = str .. "["
    for i = 1, #t, 1 do
        if i ~= 1 then 
            str = str .. ','
        end 
        if type(t[i]) == "table" then 
            str = str .. tbl_to_str(t[i], str)
        else 
            str = str .. tostring(t[i])
        end 
    end
    str = str .. "]"
    return str
end

callable = function(t)
  if t.__ then
      for _, mm in ipairs(t) do t['__'..mm] = t.__[mm] end
  end
  return setmetatable(t, { __call = t.__call })
end

-- blanke_require("ecs")

memoize = nil
do
  local mem_cache = {}
  setmetatable(mem_cache, {__mode = "kv"})
  memoize = function(f, cache)
      -- default cache or user-given cache?
      cache = cache or mem_cache
      if not cache[f] then 
          cache[f] = {}
      end 
      cache = cache[f]
      return function(...)
          local args = {...}
          local cache_str = '<no-args>'
          local found_args = false
          for i, v in ipairs(args) do
              if v ~= nil then 
                  if not found_args then 
                      found_args = true 
                      cache_str = ''
                  end

                  if i ~= 1 then 
                      cache_str = cache_str .. '~'
                  end 
                  if type(v) == "table" then
                      cache_str = cache_str .. tbl_to_str(v)
                  else
                      cache_str = cache_str .. tostring(v)
                  end
              end
          end 
          -- retrieve cached value?
          local ret = cache[cache_str]
          if not ret then
              -- not cached yet
              ret = { f(unpack(args)) }
              cache[cache_str] = ret 
              -- print('store',cache_str,'as',unpack(ret))
          end
          return unpack(ret)
      end
  end
end 

-- is given version greater than or equal to current LoVE version?
ge_version = function(major, minor, rev)
  if major and major > Game.love_version[1] then return false end
  if minor and minor > Game.love_version[2] then return false end
  if rev and rev > Game.love_version[3] then return false end
  return true
end

--TABLE
table.update = function (old_t, new_t, keys)
  if keys == nil then
      for k, v in pairs(new_t) do
          old_t[k] = v
      end
  else
      for _,k in ipairs(keys) do if new_t[k] ~= nil then old_t[k] = new_t[k] end end
  end
  return old_t
end
table.keys = function (t)
  ret = {}
  for k, v in pairs(t) do table.insert(ret,k) end
  return ret
end
table.every = function (t, fn)
  for k,v in pairs(t) do if fn ~= nil and not fn(v, k) or not v then return false end end
  return true
end
table.some = function (t, fn)
  for k,v in pairs(t) do if fn ~= nil and fn(v, k) or v then return true end end
  return false
end
table.len = function (t)
  c = 0
  for k,v in pairs(t) do c = c + 1 end
  return c
end
table.hasValue = function (t, val)
  for k,v in pairs(t) do
      if v == val then return true end
  end
  return false
end
table.slice = function (t, start, finish)
  i, res, finish = 1, {}, finish or table.len(t)
  for j = start, finish do
      res[i] = t[j]
      i = i + 1
  end
  return res
end
table.defaults = function (t,defaults)
  for k,v in pairs(defaults) do
      if type(t) == 'table' and t[k] == nil then t[k] = v
      elseif type(v) == 'table' then table.defaults(t[k],defaults[k]) end
  end
  return t
end
table.append = function (t, new_t)
  for k,v in pairs(new_t) do
      if type(k) == 'string' then t[k] = v
      else table.insert(t, v) end
  end
end
table.filter = function(t, fn)
  local len = table.len(t)
  local offset = 0
  for o = 1, len do
      local element = t[o]
      if element then
          if fn(element, o) then -- keep element
              t[o] = nil
              t[o - offset] = element
          else -- remove element
              t[o] = nil
              offset = offset + 1
          end
      end
  end
end
table.random = function(t)
  return t[Math.random(1,#t)]
end
table.randomWeighted = function(t)
  local r = Math.random(0,100)
end
table.includes = function(t, v)
  for i = 1,#t do if t[i] == v then return true end end
  return false
end
table.join = function(t, sep, nil_str)
  local str = ''
  for i = 1, #t do
      str = str .. tostring(t[i] ~= nil and t[i] or (nil_str and 'nil'))
      if i ~= #t then
          str = str .. tostring(sep)
      end
  end
  return str
end
--STRING
function string:starts(start)
 return string.sub(self,1,string.len(start))==start
end
function string:contains(q)
  return string.match(tostring(self), tostring(q)) ~= nil
end
function string:count(str)
  local _, count = string.gsub(self, str, "")
  return count
end
function string:capitalize()
  return string.upper(string.sub(self,1,1))..string.sub(self,2)
end
function string:split(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end
function string:replace(find, replace, wholeword)
  if wholeword then
      find = '%f[%a]'..find..'%f[%A]'
  end
  return (self:gsub(find,replace))
end
string.expand = memoize(function(self, ...)
  -- version: 0.0.1
  -- code: Ketmar // Avalon Group
  -- public domain

  -- expand $var and ${var} in string
  -- ${var} can call Lua functions: ${string.rep(' ', 10)}
  -- `$' can be screened with `\'
  -- `...': args for $<number>
  -- if `...' is just a one table -- take it as args
  function ExpandVars (s, ...)
    local args = {...};
    args = #args == 1 and type(args[1]) == "table" and args[1] or args;
    -- return true if there was an expansion
    local function DoExpand (iscode)
      local was = false;
      local mask = iscode and "()%$(%b{})" or "()%$([%a%d_]*)";
      local drepl = iscode and "\\$" or "\\\\$";
      s = s:gsub(mask, function (pos, code)
        if s:sub(pos-1, pos-1) == "\\" then return "$"..code;
        else was = true; local v, err;
          if iscode then code = code:sub(2, -2);
          else local n = tonumber(code);
            if n then v = args[n]; end;
          end;
          if not v then
            v, err = loadstring("return "..code); if not v then error(err); end;
            v = v();
          end;
          if v == nil then v = ""; end;
          v = tostring(v):gsub("%$", drepl);
          return v;
        end;
      end);
      if not (iscode or was) then s = s:gsub("\\%$", "$"); end;
      return was;
    end;

    repeat DoExpand(true); until not DoExpand(false);
    return s;
  end;
  return ExpandVars(self, ...)
end)
--math
local sin, cos, rad, deg, abs, min, max = math.sin, math.cos, math.rad, math.deg, math.abs, math.min, math.max
floor = function(x) return math.floor(x+0.5) end
Math = {}
do
  for name, fn in pairs(math) do Math[name] = function(...) return fn(...) end end

  local clamp = function(x, _min, _max) return min(_max, max(_min, x)) end

  Math.clamp = clamp
  Math.sign = function(x) return (x < 0) and -1 or 1 end
  Math.seed = function(l,h) if l then love.math.setRandomSeed(l,h) else return love.math.getRandomSeed() end end
  Math.random = function(...) return love.math.random(...) end
  Math.indexTo2d = function(i, col) return math.floor((i-1)%col)+1, math.floor((i-1)/col)+1 end
  Math.getXY = memoize(function(angle, dist) return dist * cos(angle), dist * sin(angle) end)
  Math.distance = memoize(function(x1,y1,x2,y2) return math.sqrt( (x2-x1)^2 + (y2-y1)^2 ) end)
  Math.lerp = function(a,b,t) 
      local r = a * (1-t) + b * t
      if a < b then return clamp(r, a, b) 
      else return clamp(r, b, a) end
  end 
  Math.prel = function(a,b,v) -- returns what percent v is between a and b
      if v >= b then return 1
      elseif v <= a then return 0
      else return (v - a) / (b - a) end
  end
  Math.sinusoidal = function(min, max, spd, percent) return Math.lerp(min, max, Math.prel(-1, 1, math.cos(Math.lerp(0,math.pi/2,percent or 0) + (Game.time * (spd or 1)) )) ) end
  --  return min + -math.cos(Math.lerp(0,math.pi/2,off or 0) + (Game.time * spd)) * ((max - min)/2) + ((max - min)/2) end
  Math.angle = memoize(function(x1, y1, x2, y2) return math.atan2((y2-y1), (x2-x1)) end)
  Math.pointInShape = function(shape, x, y)
      local pts = {}
      for p = 1,#shape,2 do
          table.insert(pts, {x=shape[p], y=shape[p+1]})
      end
      return PointWithinShape(pts,x,y)
  end

  function PointWithinShape(shape, tx, ty)
      if #shape == 0 then
          return false
      elseif #shape == 1 then
          return shape[1].x == tx and shape[1].y == ty
      elseif #shape == 2 then
          return PointWithinLine(shape, tx, ty)
      else
          return CrossingsMultiplyTest(shape, tx, ty)
      end
  end

  function BoundingBox(box, tx, ty)
      return	(box[2].x >= tx and box[2].y >= ty)
          and (box[1].x <= tx and box[1].y <= ty)
          or  (box[1].x >= tx and box[2].y >= ty)
          and (box[2].x <= tx and box[1].y <= ty)
  end

  function colinear(line, x, y, e)
      e = e or 0.1
      m = (line[2].y - line[1].y) / (line[2].x - line[1].x)
      local function f(x) return line[1].y + m*(x - line[1].x) end
      return math.abs(y - f(x)) <= e
  end

  function PointWithinLine(line, tx, ty, e)
      e = e or 0.66
      if BoundingBox(line, tx, ty) then
          return colinear(line, tx, ty, e)
      else
          return false
      end
  end

  -- from http://erich.realtimerendering.com/ptinpoly/
  function CrossingsMultiplyTest(pgon, tx, ty)
      local i, yflag0, yflag1, inside_flag
      local vtx0, vtx1

      local numverts = #pgon

      vtx0 = pgon[numverts]
      vtx1 = pgon[1]

      -- get test bit for above/below X axis
      yflag0 = ( vtx0.y >= ty )
      inside_flag = false

      for i=2,numverts+1 do
          yflag1 = ( vtx1.y >= ty )

          --[[ Check if endpoints straddle (are on opposite sides) of X axis
           * (i.e. the Y's differ); if so, +X ray could intersect this edge.
           * The old test also checked whether the endpoints are both to the
           * right or to the left of the test point.  However, given the faster
           * intersection point computation used below, this test was found to
           * be a break-even proposition for most polygons and a loser for
           * triangles (where 50% or more of the edges which survive this test
           * will cross quadrants and so have to have the X intersection computed
           * anyway).  I credit Joseph Samosky with inspiring me to try dropping
           * the "both left or both right" part of my code.
           --]]
          if ( yflag0 ~= yflag1 ) then
              --[[ Check intersection of pgon segment with +X ray.
               * Note if >= point's X; if so, the ray hits it.
               * The division operation is avoided for the ">=" test by checking
               * the sign of the first vertex wrto the test point; idea inspired
               * by Joseph Samosky's and Mark Haigh-Hutchinson's different
               * polygon inclusion tests.
               --]]
              if ( ((vtx1.y - ty) * (vtx0.x - vtx1.x) >= (vtx1.x - tx) * (vtx0.y - vtx1.y)) == yflag1 ) then
                  inside_flag =  not inside_flag
              end
          end

          -- Move to the next pair of vertices, retaining info as possible.
          yflag0  = yflag1
          vtx0    = vtx1
          vtx1    = pgon[i]
      end

      return  inside_flag
  end

  function GetIntersect( points )
      local g1 = points[1].x
      local h1 = points[1].y

      local g2 = points[2].x
      local h2 = points[2].y

      local i1 = points[3].x
      local j1 = points[3].y

      local i2 = points[4].x
      local j2 = points[4].y

      local xk = 0
      local yk = 0

      if checkIntersect({x=g1, y=h1}, {x=g2, y=h2}, {x=i1, y=j1}, {x=i2, y=j2}) then
          local a = h2-h1
          local b = (g2-g1)
          local v = ((h2-h1)*g1) - ((g2-g1)*h1)

          local d = i2-i1
          local c = (j2-j1)
          local w = ((j2-j1)*i1) - ((i2-i1)*j1)

          xk = (1/((a*d)-(b*c))) * ((d*v)-(b*w))
          yk = (-1/((a*d)-(b*c))) * ((a*w)-(c*v))
      end
      return xk, yk
  end
end
--UTIL.extra
switch = function(val, choices)
  if choices[val] then choices[val]()
  elseif choices.default then choices.default() end
end
-- for sorting a table of objects
sort = nil 
do 
  sort = function(t, key, default)
      if #t == 0 then return end
      table.sort(t, function(a, b)
          if a == nil and b == nil then
              return false
          end
          if a == nil then
              return true
          end
          if b == nil then
              return false
          end
          if a[key] == nil then a[key] = default end
          if b[key] == nil then b[key] = default end
          return a[key] < b[key]
      end)
  end
end

iterate = function(t, fn)
  if not t then return end
  local len = #t
  local offset = 0
  local removals = {}
  for o=1,len do
      local obj = t[o]
      if obj then
          if fn(obj, o) == true then
              table.insert(removals, o)
          end
      end
  end
  if #removals > 0 then
      for i = #removals, 1, -1 do
          table.remove(t, removals[i])
      end
  end
end

local nonzero_z = false
local iterateEntities = function(t, test_val, fn)
  if not t then return end
  local len = #t
  local offset = 0
  local removals = {}
  for o=1,len do
      local obj = t[o]
      if obj then
          if obj.destroyed or not obj[test_val] or fn(obj, o) == true then
              table.insert(removals, o)
          elseif obj._last_z ~= obj.z then
              obj._last_z = obj.z
              reorder = true
              Game.sortDrawables()
          end
      end
  end
  if #removals > 0 then
      for i = #removals, 1, -1 do
          table.remove(t, removals[i])
      end
  end

  return reorder
end

copy = function(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local t_copy
  if orig_type == 'table' then
      if copies[orig] then
          t_copy = copies[orig]
      else
          t_copy = {}
          copies[orig] = t_copy
          for orig_key, orig_value in next, orig, nil do
              t_copy[copy(orig_key, copies)] = copy(orig_value, copies)
          end
          setmetatable(t_copy, copy(getmetatable(orig), copies))
      end
  else -- number, string, boolean, etc
      t_copy = orig
  end
  return t_copy
end
is_object = function(o) return type(o) == 'table' and o.init and type(o.init) == 'function' end

encrypt = function(str, code, seed)
  local oldseed = {Math.seed()}
  if not seed then
      seed = 0
      for c = 1, string.len(code) do
          seed = seed + string.byte(string.sub(code,c,c))
      end
  end
  Math.seed(seed)
  local ret_str = ''
  local code_len = string.len(code)
  for c = 1, string.len(str) do
      ret_str = ret_str .. string.char(bit.bxor(string.byte(string.sub(str,c,c)), (c + Math.random(c,code_len)) % code_len))
  end
  Math.seed(unpack(oldseed))
  return ret_str
end
decrypt = function(str, code, seed)
  local oldseed = {Math.seed()}
  if not seed then
      seed = 0
      for c = 1, string.len(code) do
          seed = seed + string.byte(string.sub(code,c,c))
      end
  end
  Math.seed(seed)
  local ret_str = ''
  local code_len = string.len(code)
  for c = 1, string.len(str) do
      ret_str = ret_str .. string.char(bit.bxor(string.byte(string.sub(str,c,c)), (c + Math.random(c,code_len)) % code_len))
  end
  Math.seed(unpack(oldseed))
  return ret_str
end
local lua_print = print
do
  local str = ''
  local args
  print = function(...)
      str = ''
      args = {...}
      len = table.len(args)
      for i = 1,len do
          str = str .. tostring(args[i] or 'nil')
          if i ~= len then str = str .. ' ' end
      end
      lua_print(str)
  end
end

--CACHE
Cache = {}
do
  local storage = {}
  Cache.group = function(name) return Cache[name] end
  Cache.key = function(group_name, key) return (Cache[group_name] and Cache[group_name][key]) end
  Cache.get = function(group_name, key, fn_not_found)
      if not storage[group_name] then storage[group_name] = {} end
      if storage[group_name][key] then
          return storage[group_name][key]
      elseif fn_not_found then
          storage[group_name][key] = fn_not_found(key)
          return storage[group_name][key]
      end
  end
  Cache.stats = function()
      local str = ''
      for name, list in pairs(storage) do
          str = str .. name .. '=' .. table.len(list) .. ' '
      end
      print(str)
  end
end

--STACK
Stack = class{
  init = function(self, fn_new)
      self.stack = {} -- { { used:t/f, value:?, is_stack:true, release:fn() } }
      self.fn_new = fn_new
  end,
  new = function(self, remake)
      local found = false
      for _, s in ipairs(self.stack) do
          if not s.used then
              found = true
              s.used = true
              if remake then
                  s.value = self.fn_new()
              end
              return s
          end
      end
      if not found then
          local new_uuid = uuid()
          local new_stack_obj = {
              uuid=new_uuid,
              used=true,
              value=self.fn_new(obj),
              is_stack=true
          }
          table.insert(self.stack, new_stack_obj)
          return new_stack_obj
      end
  end,
  release = function(self, object)
      for _, s in ipairs(self.stack) do
          if s.uuid == object.uuid then
              s.used = false
              return
          end
      end
  end
}