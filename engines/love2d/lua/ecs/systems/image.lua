local draw_object = World.render
local extract_draw_components = EcsUtil.extract_draw_components
local get_draw_components = EcsUtil.get_draw_components

local update_batch_image, remove_batch_image, update_image, remove_image

local BATCH_LIMIT = 5000
local AUTO_BATCH_LIMIT = 20 -- TODO implement later (automatically starts batching an image after this limit)

local get_batch_key = function(obj, sb_index)
    obj_entity = get_entity(obj)
    return 'imagebatch' .. '.' .. (obj_entity.z or 0) .. '.' .. sb_index .. '.' .. Game.res('image',obj.path)
end

local use_size = function(obj, object)
    local obj_entity = get_entity(obj)
    if obj.use_size then 
        if object then 
            obj_entity.size.width = object:getWidth()
            obj_entity.size.height = object:getHeight()
        else
            obj_entity.size.width = 1
            obj_entity.size.height = 1
        end
    end
end

local batches = {} -- { 'blanke.imagebatch.<z>.<sb_index>.res_path' = batch_obj }
update_batch_image = function(obj) 
    local obj_entity = get_entity(obj)
    obj.object = nil -- remove ordinary Image

    if not obj.path then 
        remove_batch_image(obj)
        return 
    end
    remove_image(obj)
    
    local img_object = Cache.get('Image', Game.res('image',obj.path), function(key)
        return love.graphics.newImage(key)
    end)

    local sb_index = 1
    local batch_key = get_batch_key(obj, sb_index)
    -- is this batch full?
    local sb = Cache.get('blanke.imagebatch', batch_key, function(key)
        return love.graphics.newSpriteBatch(img_object, BATCH_LIMIT)
    end)
    while sb:getCount() >= sb:getBufferSize() do 
        sb_index = sb_index+1
        batch_key = get_batch_key(obj, sb_index)
        sb = Cache.get('blanke.imagebatch', batch_key, function(key)
            return love.graphics.newSpriteBatch(img_object, BATCH_LIMIT)
        end)
    end
    if not batches[batch_key] then
        -- create spritebatch if it doesn't exist
        batches[batch_key] = ImageBatch{
            key=batch_key,
            object=sb,
            z=obj_entity.z
        }
    end
    local batch = batches[batch_key]
    local old_batch = batches[obj_entity.batch_key] 
    if old_batch and batch_key ~= obj_entity.batch_key then 
        -- remove from old batch
        old_batch.object:set(obj_entity.batch_id, 0, 0, 0, 0, 0)
    end
    obj_entity.batch_key = batch_key
    if not obj_entity.batch_id then 
        obj_entity.batch_id = batch.object:add(0, 0, 0, 0, 0)
    end
    use_size(obj, img_object)
end
remove_batch_image = function(obj)
    local obj_entity = get_entity(obj)
    local batch_key = obj_entity.batch_key
    if batch_key then 
        local old_batch = batches[obj_entity.batch_key] 
        if old_batch then 
            -- remove from batch
            old_batch.object:set(obj_entity.batch_id, 0, 0, 0, 0, 0)
        end
    end
    obj.object = nil
    obj_entity.batch_key = nil
    obj_entity.batch_id = nil
end 
update_image = function(obj)    
    if obj.path then
        remove_batch_image(obj)
        obj.object = Cache.get('Image', Game.res('image',obj.path), function(key)
            return love.graphics.newImage(key)
        end)
        use_size(obj, obj.object)
    else 
        remove_image(obj)
    end
end
remove_image = function(obj)
    obj.object = nil
    use_size(obj)
end

Component('image', { batch=true, use_size=true } )

System{
    component='image',
    requires=EcsUtil.require_draw_components(),
    add = function(obj)
        local obj_entity = get_entity(obj)
        track(obj, 'path')
        track(obj, 'batch')
        track(obj_entity, 'z')

        if obj.path then 
            if obj.batch then 
                update_batch_image(obj)
            else 
                update_image(obj)
            end
        end        
    end,
    update = function(obj, dt)
        local obj_entity = get_entity(obj)
        if changed(obj, 'path') or (obj.batch and changed(obj_entity, 'z')) then 
            if not obj.path then 
                remove_image(obj)
                remove_batch_image(obj)
            elseif obj.batch then 
                update_batch_image(obj)
            else 
                update_image(obj)
            end
        end
        if obj_entity.batch_key then
            local batch = batches[obj_entity.batch_key]
            local comps = {get_draw_components(obj_entity)}
            -- print(batch.object:getCount(), obj_entity.batch_key, '<-', obj_entity.batch_id)
            batch.object:set(obj_entity.batch_id, get_draw_components(obj_entity))
        end
    end,
    draw = function(obj)
        if not obj then return true end
        if obj.object then
            draw_object(obj, get_entity(obj))
        end
    end
}

ImageBatch = Spawner("blanke.imagebatch")

System{
    type='blanke.imagebatch',
    add = function(obj)
        extract_draw_components(obj)
    end,
    draw = function(obj)
        draw_object(obj)
    end
}

-- config functions
Image = {
    animation = function() 

    end
}