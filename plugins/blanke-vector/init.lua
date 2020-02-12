local range = 10000000

Vector = setmetatable({
    random2D = function()
        return Vector(Math.random(-range,range)/range, Math.random(-range,range)/range)
    end,
    random3D = function()
        return Vector(Math.random(-range,range)/range, Math.random(-range,range)/range, Math.random(-range,range)/range)
    end
},{
    __call = function(self, x, y, z)
        return setmetatable({
            x = x or 0, y = y or 0, z = z or 0,
            is_vector = true,
            array = function(self)
                return { self.x, self.y, self.z }
            end,
            matrix = function(self)
                return { {self.x}, {self.y}, {self.z} }
            end,
            mult = function(self,s)
                self.x = self.x * s
                self.y = self.y * s 
                self.z = self.z * s 
                return self
            end,
            set = function(self, x, y, z)
                if not y and not z then
                    -- x = vector
                    if x.is_vector then 
                        self.x, self.y, self.z = x.x, x.y, x.z
                    else 
                    -- x = table 
                        self.x, self.y, self.z = x[1] or self.x, x[2] or self.y, x[3] or self.z
                    end 
                elseif not z then 
                    self.x, self.y = x, y
                elseif x and y and z then 
                    self.x, self.y, self.z = x, y, z
                end 
                return self
            end,

        },{
            __tostring = function(self)
                return string.format("Vector(%d, %d, %d)", self.x, self.y, self.z)
            end,
            __index = function(self, k) return rawget(self,k) end 
        })
    end,
})

function matprint(a)
    local str = ''
    for r, row in ipairs(a) do
        str = '[\t'
        for c, col in ipairs(row) do 
            str = str .. col .. '\t'
        end 
        str = str .. ']'
        print(str)
    end 
end 

function matmul(a, b)
    local was_vector = false
    if a.is_vector then -- just swap the arguments
        local temp = a 
        a = b 
        b = temp 
    end
    if b.is_vector then 
        was_vector = true
        b = b:matrix()
        assert(#a[1] == 3, "matrix columns ("..#a[1]..") ~= vector size (".. #b ..")")
    else 
        assert(#a[1] == #b, "mat_a columns ("..#a[1]..") ~= mat_b rows ("..#b..")")
    end
    local ret = {}
    local rows_a, cols_a, rows_b, cols_b = #a, #b, #a[1], #b[1]
    for i = 1, rows_a do 
        for j = 1, cols_b do 
            local sum = 0
            for k = 1, cols_a do 
                sum = sum + a[i][k] * b[k][j]
            end 
            if not ret[i] then ret[i] = {} end 
            ret[i][j] = sum
        end 
    end 
    if was_vector then 
        return Vector((ret[1] or {})[1], (ret[2] or {})[1], (ret[3] or {})[1])
    else 
        return ret
    end 
end 