local draw_object = EcsUtil.draw_object
local extract_draw_components = EcsUtil.extract_draw_components
local get_draw_components = EcsUtil.get_draw_components

local update_batch_image, remove_batch_image, update_image, remove_image

local BATCH_LIMIT = 2001
local AUTO_BATCH_LIMIT = 20 -- TODO implement later (automatically starts batching an image after this limit)

local get_batch_key = function(obj, sb_index)
    return 'imagebatch' .. '.' .. (obj.z or 0) .. '.' .. sb_index .. '.' .. Game.res('image',obj.image.path)
end

local batches = {} -- { 'blanke.imagebatch.<z>.<sb_index>.res_path' = batch_obj }
update_batch_image = function(obj) 
    obj.image.object = nil

    if not obj.image.path then 
        remove_batch_image(obj)
        return 
    end
    remove_image(obj)
    
    local sb_index = 1
    local batch_key = get_batch_key(obj, sb_index)
    local img_object = Cache.get('Image', Game.res('image',obj.image.path), function(key)
        return love.graphics.newImage(key)
    end)
    -- is this batch full?
    local sb = Cache.get('blanke.imagebatch', batch_key, function(key)
        return love.graphics.newSpriteBatch(img_object)
    end)
    while sb:getCount() > (BATCH_LIMIT or sb:getBufferSize()) do 
        sb_index = sb_index+1
        batch_key = get_batch_key(obj, sb_index)
        sb = Cache.get('blanke.imagebatch', batch_key, function(key)
            return love.graphics.newSpriteBatch(img_object)
        end)
    end
    if not batches[batch_key] then
        -- create spritebatch if it doesn't exist
        batches[batch_key] = {
            type='blanke.imagebatch',
            key=batch_key,
            object=sb,
            z=obj.z
        }
        World.add(batches[batch_key])
    end
    local batch = batches[batch_key]
    local old_batch = batches[obj.image.batch_key] 
    if old_batch and batch_key ~= obj.image.batch_key then 
        -- remove from old batch
        old_batch.object:set(obj.image.batch_id, 0, 0, 0, 0, 0)
    end
    obj.image.batch_key = batch_key
    obj.image.batch_id = batch.object:add(get_draw_components(obj))
    extract(obj, 'size', { width=img_object:getWidth(), height=img_object:getHeight() }, true)
end
remove_batch_image = function(obj)
    local image_obj = obj.image
    local batch_key = image_obj.batch_key
    if batch_key then 
        local old_batch = batches[image_obj.batch_key] 
        if old_batch then 
            -- remove from batch
            old_batch.object:set(image_obj.batch_id, 0, 0, 0, 0, 0)
        end
    end
    obj.image.object = nil
    image_obj.batch_key = nil
    image_obj.batch_id = nil
end 
update_image = function(obj)
    local image_obj = obj.image
    
    if image_obj.path then
        remove_batch_image(obj)
        image_obj.object = Cache.get('Image', Game.res('image',image_obj.path), function(key)
            return love.graphics.newImage(key)
        end)
        if image_obj.use_size then extract(obj, 'size', { width=image_obj.object:getWidth(), height=image_obj.object:getHeight() }, true) end
    else 
        remove_image(obj)
    end
end
remove_image = function(obj)
    obj.image.object = nil
    if obj.image.use_size then extract(obj, 'size', nil, true) end
end

Component('image', { batch=true, use_size=true } )
Image = System{
    'image',
    type="blanke.image",
    add = function(obj)
        extract(obj, 'image')
        extract_draw_components(obj)
        track(obj.image, 'path')
        track(obj.image, 'batch')
        track(obj, 'z')

        if obj.image.path then 
            if obj.image.batch then 
                update_batch_image(obj)
            else 
                update_image(obj)
            end
        end
    end,
    update = function(obj, dt)
        if changed(obj.image, 'path') or (obj.image.batch and changed(obj, 'z')) then 
            if not obj.image.path then 
                remove_image(obj)
                remove_batch_image(obj)
            elseif obj.image.batch then 
                update_batch_image(obj)
            else 
                update_image(obj)
            end
        end
        if obj.image.batch_key then
            local batch = batches[obj.image.batch_key]
            batch.object:set(obj.image.batch_id, get_draw_components(obj))
        end
    end,
    draw = function(obj)
        local image_obj = obj.image
        if not image_obj then return true end
        if image_obj.object then 
            draw_object(image_obj, obj)
        end
    end
}

System{
    type='blanke.imagebatch',
    add = function(obj)
        extract_draw_components(obj)
    end,
    draw = function(obj)
        draw_object(obj)
    end
}