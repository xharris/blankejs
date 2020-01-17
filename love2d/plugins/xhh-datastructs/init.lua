Array = nil
do 
    Array = setmetatable({},{
        __call = function(t, ...)
            local elements = {...}
            local arr = setmetatable({},{
                __index = function(t, k)
                    if type(k) == "number" then 
                        return elements[k]
                    end
                    if k == 'length' then return #elements end
                    return rawget(t,k)
                end,
                __newindex = function(t, k, v)
                    if type(k) == "number" then 
                        elements[k] = v
                    end
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

            -- push
            -- pop: remove from end -> removed val
            -- shift: remove from from
            -- unshift: add to front
            -- removeAt(i,amt)
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