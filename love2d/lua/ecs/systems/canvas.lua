local draw_object = EcsUtil.draw_object
local extract_draw_components = EcsUtil.extract_draw_components

local canvas_stack = Stack(function(obj)
    return love.graphics.newCanvas(obj.size.width, obj.size.height)
end)

Canvas = System{
    type="blanke.canvas",
    template={
        auto_clear=true,
        auto_draw=true,
        setup=true
    },
    add = function(obj)
        extract_draw_components(obj, {
            pos={ x=0, y=0 },
            size={ width=Game.width, height=Game.height }
        })
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
        obj.draw = function(obj)
            if not obj.active and obj.drawn then
                draw_object(obj)
                obj.drawn = false
            end
            return obj
        end
        obj.setup = function(obj)
            if not obj.object then 
                obj.object = canvas_stack:new(obj)
            end
            return obj
        end
        obj.release = function(obj)
            if obj.object ~= nil then 
                obj:drawTo()
                canvas_stack:release(obj.object)
                obj.object = nil
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