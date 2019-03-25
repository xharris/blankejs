Save = {
    file_path = "",
    file_name = "_",
    file_data = {}
}
    
Save.open = function(name)
    Save.file_name = name
    Save.file_path = Save.file_name
    
    -- file exists check
    if getFileInfo(Save.file_path) then
        local contents = love.filesystem.read(Save.file_path)
        Save.file_data = json.decode(contents)
    end

    return Save
end

-- open must be called first
Save.write = function(key, value)
    Save.file_data[key] = value
    Save:save()

    return Save
end

-- open must be called first
Save.read = function(key)
    return Save.file_data[key]
end

-- saves the currently loaded file
Save.save = function()
    if Save.file_path ~= '' then
        local json_data = json.encode(Save.file_data)
        local success = love.filesystem.write(Save.file_path, json_data)
    end
    return Save
end

-- check if a key exists (usually before reading)
Save.hasKey = function(key)
    return (Save.file_data[key] ~= nil)
end

Save.open('_')

return Save