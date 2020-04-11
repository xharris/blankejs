local draw_object = EcsUtil.draw_object
local extract_draw_components = EcsUtil.extract_draw_components
local get_draw_components = EcsUtil.get_draw_components

local batches = {} -- { 'z.res_path' = batch_obj }
local update_image = function(obj) 
    local batch_key = 'imagebatch' .. '.' .. (obj.z or 0) .. '.' .. Game.res('image',obj.image.path)
    local img_object = Cache.get('Image', Game.res('image',obj.image.path), function(key)
        return love.graphics.newImage(key)
    end)
    if not batches[batch_key] then
        -- create spritebatch if it doesn't exist
        batches[batch_key] = {
            type='blanke.imagebatch',
            object=Cache.get('blanke.imagebatch', batch_key, function(key)
                return love.graphics.newSpriteBatch(img_object)
            end),
            z=obj.z
        }
        World.add(batches[batch_key])
    end
    local batch = batches[batch_key]
    local old_batch = batches[obj.image.batch_key] 
    if old_batch and batch_key ~= obj.image.batch_key then 
        -- remove from old batch
        --old_batch.object:set(obj.image.batch_id, 0, 0, 0, 0, 0)
    end
    obj.image.batch_key = batch_key
    obj.image.batch_id = batch.object:add(get_draw_components(obj))
    obj.size = extract(obj, 'size', { width=img_object:getWidth(), height=img_object:getHeight() }, true)
    print('id',obj.image.batch_id, batch.uuid, batch.uuid)
    print_r(obj.image)
end

Component('image', { path='', batch=true } )
System{
    'image',
    add = function(obj)
        extract_draw_components(obj)
        
        track(obj.image, 'path')
        track(obj, 'z')
        update_image(obj)
    end,
    update = function(obj, dt)
        if changed(obj.image, 'path') or (obj.image and changed(obj, 'z')) then 
            update_image(obj)
        end
        local batch = batches[obj.image.batch_key]
        if batch then 
            batch.object:set(obj.image.batch_id, get_draw_components(obj))
        end
    end,
    draw = function(obj)
        if not obj.image then return true end
        if obj.image and not obj.image.batch then 
            draw_object(obj)
        end
    end
}

Image = callable {
    __call = function(_)

    end,
    animation = function()

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