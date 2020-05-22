Array = nil
Set = nil
do
    local arr_metamethods = {
        __index = function(t, k)
            if type(k) == "number" then
                return t.table[k]
            end
            if k == 'length' then
                return #t.table
            end
            return rawget(t,k)
        end,
        __newindex = function(t, k, v)
            if type(k) == "number" then
                t.table[k] = v
            end
        end,
        __tostring = function(t)
            local str = ''
            for i,v in ipairs(t.table) do
                str = str .. tostring(v)
                if i ~= #t.table then
                    str = str .. ","
                end
            end
            return str
        end
    }

    local arr_methods = {
        table = {},
        shift = function(self, ...)
            for i,v in ipairs({...}) do
                table.insert(self.table, 1, v)
            end
        end,
        push = function(self, ...)
            for i,v in ipairs({...}) do
                table.insert(self.table, v)
            end
        end,
        pop = function(self)
            local last = self.table[#self.table]
            self.table[#self.table] = nil
            return last
        end,
        remove = function(self, start, amt)
            amt = amt or 1
            local off = 0
            local new_arr = {}
            for i = 1,self.length do
                if i >= start and i < start + amt then
                    off = off + 1
                else
                    new_arr[i-off] = self.table[i]
                end
            end
            self.table = new_arr
        end,
        copy = function(self)
            local ret = Array.from(copy(self.table))
            return ret
        end,
        includes = function(self, v)
            for i = 1,self.length do if self.table[i] == v then return true end end
            return false
        end,
        fill = function(self, v, s, e)
            s = s or 1
            e = e or self.length             for i = s, e do self.table[i] = v end
        end,
        indexOf = function(self, v)
            for i = 1, self.length do if self.table[i] == v then return i end end
            return 0
        end,
        forEach = function(self, fn)
            for i = 1, self.length do
                if fn(self.table[i], i) == true then break end
            end
        end,
        map = function(self, fn)
            for i = 1, self.length do self.table[i] = fn(self.table[i], i) end
            return self
        end,
        filter = function(self, fn)
            local new_arr = {}
            for i = 1, self.length do if fn(self.table[i], i) then table.insert(new_arr, self.table[i]) end end
            self.table = new_arr
            return self
        end,
        reverse = function(self)
            local new_arr = {}
            for i = self.length, 1, -1 do table.insert(new_arr, self.table[i]) end
            self.table = new_arr
            return self
        end,
        join = function(self, sep)
            local str = ''
            for i = 1, self.length do
                str = str .. tostring(self.table[i])
                if i ~= self.length then
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
            for i = 1, self.length do if fn(self.table[i], i) == true then return true end end
            return false
        end,
        every = function(self, fn)
            for i = 1, self.length do if fn(self.table[i], i) == false then return false end end
            return true
        end,
        sort = function(self, ...) table.sort(self.table, ...) end,
        shuffle = function(self)
            local tbl = {}
            local t = self.table
            for i = 1, #t do
                tbl[i] = t[i]
            end
            for i = #tbl, 2, -1 do
                local j = math.random(i)
                tbl[i], tbl[j] = tbl[j], tbl[i]
            end
            self.table = tbl
        end,
        sort = function(self, fn)
            table.sort(self.table, fn)
        end,
        random = function(self)
            return table.random(self.table)
        end
        --reduce
    }

    Array = setmetatable({
        from = function(t)
            return Array(unpack(t))
        end
    },{
        __call = function(t, ...)
            local arr = setmetatable(copy(arr_methods), copy(arr_metamethods))
            for i,v in ipairs({...}) do
                arr:push(v)
            end
            return arr
        end
    })

    local set_methods = copy(arr_methods)
    set_methods.push = function(self, ...)
        for i,v in ipairs({...}) do
            if not self:includes(v) then
                table.insert(self.table, v)
            end
        end
    end
    set_methods.copy = function(self)
        local ret = Set.from(copy(self.table))
        return ret
    end

    local set_metamethods = copy(arr_metamethods)
    set_metamethods.__index = function(t,k)
        if k == 'push' or k == 'copy' then
            return rawget(t,k)
        else
            return arr_metamethods.__index(t,k)
        end
    end

    Set = setmetatable({
        from = function(t)
            return Set(unpack(t))
        end
    },{
        __call = function(t, ...)
            local set = setmetatable(copy(set_methods), copy(set_metamethods))
            for i,v in ipairs({...}) do
                set:push(v)
            end
            return set
        end
    })
end
