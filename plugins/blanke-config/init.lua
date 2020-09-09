--CONFIG
Config = nil
do 
    local configs = {}

    _Config = class{
        init = function(self, name, big_info)
            self.uuid2config = {}
            self.key2uuid = {}
            self.uuid2count = {}
            
            if big_info then 
                for k, v in pairs(big_info) do 
                    self:add({ k }, v)
                end
            end
            
            configs[name] = self
        end,
        add = function(self, keys, info)
            local id
            -- info = previously added key
            if type(info) == "string" and self.key2uuid[info] then 
                info = self.key2uuid[info]
            else
                id = uuid()
            end
            -- pair key with id
            for _, key in ipairs(keys) do 
                self.key2uuid[key] = id
            end
            -- add to uuid cound
            if not self.uuid2count[id] then self.uuid2count[id] = 0 end
            self.uuid2count[id] = self.uuid2count[id] + 1
            -- store info
            self.uuid2config[id] = info
        end,
        get = function(self, key)
            local id = self.key2uuid[key]
            if id then return self.uuid2config[id] end
        end,
        update = function(self, key, info)
            local id = self.key2uuid[key]
            if id then
                table.update(self.uuid2config[id], info)
            end
        end,
        remove = function(self, key)
            local id = self.key2uuid[key]
            if id then 
                self.uuid2count[id] = self.uuid2count[id] - 1
                if self.uuid2count[id] <= 0 then 
                    self.uuid2count[id] = 0
                    self.uuid2config[id] = nil
                end
                self.key2uuid[key] = nil
            end
        end,
        iterateKeys = function(self, fn)
            for key, id in pairs(self.key2uuid) do 
                fn(key, self.uuid2config[id])
            end
        end,
        iterateInfo = function(self, fn)
            for id, info in pairs(self.uuid2config) do 
                fn(info)
            end
        end
    }
    
    Config = callable {
        __call = function(_, name, info)
            if info then 
                return _Config(name, info)
            else
                assert(name and configs[name],"Config \'"..tostring(name).."\' not found")
                return configs[name]
            end
        end
    }
end

return Config