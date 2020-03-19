class = require "lua.clasp"
require "lua.print_r"
table.len = function (t) 
    c = 0
    for k,v in pairs(t) do c = c + 1 end
    return c
end
lua_print = print 
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

local callable = function(t) 
    if t.__ then 
        for _, mm in ipairs(t) do t['__'..mm] = t.__[mm] end 
    end
    return setmetatable(t, { __call = t.call })
end

do 
    local system_list = {}
    local system_objs = {} -- { sys_name : {} }

    local _System = class {

    }

    System = class {
        init = function(self, args)
            local components = {}
            if args then 
                for c = 1, #args do 
                    -- required components
                    print('component',args[c])
                end
                for name, fn in pairs(args) do 
                    if type(name) ~= 'number' then 
                        if type(fn) == 'function' then 
                            -- system processor
                            print('fn',name)
                        else 
                            -- default value
                        end
                    end
                end
            end
            system_list[self] = self
        end,
        call = function(fn_name, ...)
            for _, sys in ipairs(system_list) do 
                
            end
        end,
        add = function(name, obj)
            
        end,
        __ = {
            call = function(self)
                print('ok hi there')
            end 
        }
    }
end

-- register defaults for a component
Component = callable{
    call = function(name, props)

    end
}

Component('position', { x = 0, y = 0 })
Component('hitbox', { width = 0, height = 0 })

Hitbox = System{
    new = function(obj, args)

    end,
    update = function(obj, dt)
        
    end,
    draw = function(obj)

    end,
    destroy = function(obj)

    end
}

State = System()--'state', {}, {})

InputConfig = function(inputs)

end

love.load = function()
    print(Hitbox)
end

love.update = function(dt)
    System.call('update',dt)
end

love.draw = function()
    System.call('draw')
end