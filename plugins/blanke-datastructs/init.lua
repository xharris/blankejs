Array = nil
do 
    Array = setmetatable({},{
        __call = function(t, ...)
            local elements = {...}
            local len = #elements
            local arr = setmetatable({},{
                __index = function(t, k)
                    if type(k) == "number" then 
                        return elements[k]
                    end
                    len = #elements
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

            function arr:forEach(fn)
                for i,v in ipairs(elements) do
                    fn()
                end
            end
            
            function arr:insert(i)
                
            end

            function arr:remove(start, amt)
                amt = amt or 1
                local off = 0
                local new_arr = {}
                for i = 1,len do
                    if i >= start + (amt - 1)
                    new_arr[i] = elements[i]
                end 
            end

            function arr:push(v) table.insert(elements, v) end

            function arr:pop()
                local last = elements[#elements]
                elements[#elements] = nil
                return last
            end
            --includes(val)

            function arr:copy()
                local ret = {}
                for k,v in pairs(elements) do ret[k] = v end 
                return ret
            end

            --fill(value,[s,e])
            --sort(fn)
            --filter(fn) -> array

            return arr
        end
    })
end