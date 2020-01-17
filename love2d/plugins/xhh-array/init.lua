Array = nil
do 
    Array = setmetatable({
        from = function(t)
            return Array(unpack(t))
        end
    },{
        __call = function(t, ...)
            local elements = {...}
            local len = #elements
            -- table was given as arg
            if len == 1 and type(elements[1]) == "table" then 
                elements = elements[1]
                len = #elements
            end
            local arr = setmetatable({
                push = function(self, ...)
                    for i,v in ipairs({...}) do
                        table.insert(elements, v)
                    end
                    len = #elements
                end,
                pop = function(self)
                    local last = elements[#elements]
                    elements[#elements] = nil
                    len = #elements
                    return last
                end,
                remove = function(self, start, amt)
                    amt = amt or 1
                    local off = 0
                    local new_arr = {}
                    for i = 1,len do
                        if i >= start and i < start + amt then 
                            off = off + 1
                        else 
                            new_arr[i-off] = elements[i]
                        end
                    end 
                    elements = new_arr
                end,
                copy = function(self)
                    local ret = Array()
                    for i = 1,len do ret[i] = elements[i] end
                    return ret
                end,
                includes = function(self, v)
                    for i = 1,len do if elements[i] == v then return true end end
                    return false
                end,
                fill = function(self, v, s, e)
                    s = s or 1
                    e = e or len
                    for i = s, e do elements[i] = v end
                end,
                indexOf = function(self, v)
                    for i = 1, len do if elements[i] == v then return i end end
                    return 0
                end,
                forEach = function(self, fn)
                    for i = 1, len do fn(elements[i], i) end
                end,
                map = function(self, fn)
                    local new_arr = Array()
                    for i = 1, len do new_arr:push(fn(elements[i], i)) end 
                    return new_arr
                end,
                filter = function(self, fn)
                    local new_arr = Array()
                    for i = 1, len do if fn(elements[i], i) == true then new_arr:push(elements[i]) end end
                    return new_arr
                end,
                reverse = function(self)
                    local new_arr = Array()
                    for i = len, 1, -1 do new_arr:push(elements[i]) end
                    return new_arr
                end,
                join = function(self, sep)
                    local str = ''
                    for i = 1, len do
                        str = str .. tostring(elements[i])
                        if i ~= len then 
                            str = str .. tostring(sep)
                        end
                    end
                    return str
                end,
                concat = function(self, ...)
                    for i,v in ipairs({...}) do 
                        if type(v) == 'table' then 
                            for i,v2 in ipairs(v) do 
                                self:push(v2)
                            end
                        else
                            self:push(v)
                        end
                    end
                end,
                some = function(self, fn)
                    for i = 1, len do if fn(elements[i], i) == true then return true end end
                    return false
                end,
                every = function(self, fn)
                    for i = 1, len do if fn(elements[i], i) == false then return false end end 
                    return true
                end,
                sort = function(self, ...) table.sort(elements, ...) end
                --sort(fn)
                --reduce
            },{
                __index = function(t, k)
                    len = #elements
                    if type(k) == "number" then 
                        return elements[k]
                    end
                    if k == 'length' then return len end
                    return rawget(t,k)
                end,
                __newindex = function(t, k, v)
                    if type(k) == "number" then 
                        elements[k] = v
                    end
                    len = #elements
                end,
                __tostring = function(t)
                    local str = ''
                    for i,v in ipairs(elements) do 
                        str = str .. tostring(v)
                        if i ~= #elements then 
                            str = str .. ","
                        end
                    end
                    return str
                end
            })
            -- push all arguments into table
            return arr
        end
    })
end