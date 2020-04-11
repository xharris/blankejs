local draw_object = EcsUtil.draw_object
local extract_draw_components = EcsUtil.extract_draw_components

local canvas_stack = Stack(function(obj)
    return love.graphics.newCanvas(obj.size.width, obj.size.height)
end)

Canvas = System{
    type="blanke.canvas",
    add = function(obj)
        extract_draw_components(obj, {
            pos={ x=0, y=0 },
            size={ width=Game.width, height=Game.height }
        })
        -- create canvas
        obj.object = canvas_stack:new(obj)
        -- functions
        obj.drawTo = function(obj, fn)
            obj.active = true
            obj.object.value:renderTo(fn)
            obj.active = false
        end
        obj.draw = function(obj)
            if not obj.active then
                draw_object(obj)
            end
        end
    end,
    draw = function(obj)
        if not obj._game_canvas then 
            obj:draw()
        end
    end,
    remove = function(obj)
        obj.object:release()
    end
}