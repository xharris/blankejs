local _NAME = ...

-- basic components
Component{
    pos             = { x = 0, y = 0 },
    vel             = { x = 0, y = 0 }
}

-- drawing components
Component{
    quad            = false,
    size            = { width = 0, height = 0 },
    angle           = 0,
    scale           = { x = 1, y = 1 },
    offset          = { x = 0, y = 0 },
    shear           = { x = 0, y = 0 },
    align           = false
}

EcsUtil = {
    extract_draw_components = function(obj, override)
        override = override or {}
        local comps = {'quad','pos','angle','size','scale','offset','shear'}
        for _, comp_name in ipairs(comps) do 
            obj[comp_name] = extract(obj, comp_name, override[comp_name], true)
        end
    end,
    draw_object = function(obj)
        local object = (obj.object and obj.object.is_stack) and obj.object.value or obj.object
        if object then 
            love.graphics.draw(object, EcsUtil.get_draw_components(obj))
        end
    end,
    get_draw_components = function(obj)
        if obj.quad then 
            return obj.quad or nil, 
            obj.pos.x, obj.pos.y,
            Math.rad(obj.angle),
            obj.scale.x, obj.scale.y,
            obj.offset.x, obj.offset.y,
            obj.shear.x, obj.shear.y
        else 
            return obj.pos.x, obj.pos.y,
            Math.rad(obj.angle),
            obj.scale.x, obj.scale.y,
            obj.offset.x, obj.offset.y,
            obj.shear.x, obj.shear.y
        end
    end
}

--CANVAS
require(_NAME..".canvas")
require(_NAME..".image")
-- require(_NAME..".effect")
-- require(_NAME..".platforming")


local calc_align = function(obj)
    local align = obj.align 
    local ax, ay = 0, 0
    if align then
        obj.size = extract(obj, 'size')
        obj.offset = extract(obj, 'offset')

        if string.contains(align, 'center') then
            ax = obj.size.width/2 
            ay = obj.size.height/2
        end
        if string.contains(align,'left') then
            ax = 0
        end
        if string.contains(align, 'right') then
            ax = obj.size.width
        end
        if string.contains(align, 'top') then
            ay = 0
        end
        if string.contains(align, 'bottom') then
            ay = obj.size.height
        end
        obj.offset = { x=floor(ax), y=floor(ay) }
    end
end
System{
    'align',
    add = function(obj)
        calc_align(obj)
        track(obj, 'align')
        track(obj.size, 'width')
        track(obj.size, 'height')
    end,
    update = function(obj, dt)
        if changed(obj, 'align') or changed(obj.size, 'width') or changed(obj.size, 'height') then 
            calc_align(obj)
        end
    end
}

System{
    'update',
    index = 2,
    update = function(obj, dt)
        obj:update(dt)
    end
}

--DRAWING
System{
    'predraw',
    predraw = function(obj)
        if obj.predraw then obj:predraw() end
    end
}

System{
    'postdraw',
    postdraw = function(obj)
        if obj.postdraw then obj:postdraw() end
    end
}
