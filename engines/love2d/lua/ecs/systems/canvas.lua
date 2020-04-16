local draw_object = EcsUtil.draw_object
local extract_draw_components = EcsUtil.extract_draw_components

local canvas_stack = Stack(function(obj)
    return love.graphics.newCanvas(Game.width, Game.height)
end)

Canvas = Spawner("blanke.canvas", {
    auto_clear=true,
    auto_draw=true,
    setup=true
})

System{
    type="blanke.canvas",
    requires=EcsUtil.require_draw_components(),
    add = function(obj)
        local entity = get_entity(obj)
        local pos = extract(entity, 'pos', { x=0, y=0 })

        local pre_setup = obj.setup
        -- functions
        obj.drawTo = function(obj, fn)
            if obj.object then
                obj.active = true
                obj.object.value:renderTo(function()
                    if obj.auto_clear then Draw.clear(obj.auto_clear) end
                    if fn then fn() end
                end)
                obj.drawn = true
                obj.active = false
            end
            return obj
        end
        obj.draw = function(obj, props_obj)
            if not obj.active and obj.drawn then
                draw_object(obj, props_obj)
                obj.drawn = false
            end
            return obj
        end
        obj.setup = function(obj)
            if not obj.object then 
                obj.object = canvas_stack:new(obj)
                obj.is_setup = true
            end
            return obj
        end
        obj.release = function(obj)
            if obj.object ~= nil then 
                obj:drawTo()
                canvas_stack:release(obj.object)
                obj.object = nil
                obj.is_setup = false
            end
            return obj
        end
        -- create canvas
        if pre_setup then 
            obj:setup()
        end
    end,
    draw = function(obj)
        if obj.auto_draw then 
            obj:draw()
        end
    end,
    remove = function(obj)
        obj:release()
    end
}