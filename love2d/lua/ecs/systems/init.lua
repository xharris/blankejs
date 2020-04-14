local _NAME = ...

-- basic components
Component{
    pos             = { x = 0, y = 0 },
    vel             = { x = 0, y = 0 }
}

-- drawing components
Component{
    quad            = { },
    size            = { width = 1, height = 1 },
    angle           = { 0 },
    scale           = { x = 1, y = 1 },
    offset          = { x = 0, y = 0 },
    shear           = { x = 0, y = 0 },
    align           = { 'top left' },
    blendmode       = { 'alpha' }
}

EcsUtil = {
    require_draw_components = function()
        return {'quad','pos','angle','size','scale','offset','shear','blendmode'}
    end,
    extract_draw_components = function(obj, override)
        override = override or {}
        local comps = {'quad','pos','angle','size','scale','offset','shear','blendmode'}
        for _, comp_name in ipairs(comps) do 
            extract(obj, comp_name, override[comp_name], true)
        end
    end,
    draw_object = function(obj, prop_obj)
        local object = obj.object 
        if object and object.is_stack then 
            object = object.value
        end
        if object then 
            local main_obj = obj 
            local blendmode = extract(main_obj, 'blendmode')
            if prop_obj then main_obj = prop_obj end
            Draw.setBlendMode(unpack(blendmode))
            love.graphics.draw(object, EcsUtil.get_draw_components(main_obj))
        end
    end,
    get_draw_components = function(obj)
        if obj.quad and obj.quad.x ~= nil then 
            return obj.quad or nil, 
            floor(obj.pos.x), floor(obj.pos.y),
            Math.rad(obj.angle[1]),
            obj.scale.x, obj.scale.y,
            floor(obj.offset.x), floor(obj.offset.y),
            obj.shear.x, obj.shear.y
        else 
            return floor(obj.pos.x), floor(obj.pos.y),
            Math.rad(obj.angle[1]),
            obj.scale.x, obj.scale.y,
            floor(obj.offset.x), floor(obj.offset.y),
            obj.shear.x, obj.shear.y
        end
    end
}

--CANVAS
require(_NAME..".canvas")
require(_NAME..".image")
--require(_NAME..".effect")
--require(_NAME..".movement")
--require(_NAME..".animation")
require(_NAME..".timer")
-- camera
-- audio?
-- map
-- physics
-- hitbox
-- net


local calc_align = function(obj)
    local align = obj.align[1] 
    local ax, ay = 0, 0
    if align then
        extract(obj, 'size')
        extract(obj, 'offset')

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
    component='align',
    requires={'size'},
    add = function(obj)
        calc_align(obj)
        track(obj.align, 0)
        track(obj.size, 'width')
        track(obj.size, 'height')
    end,
    update = function(obj, dt)
        if changed(obj.align, 0) or changed(obj.size, 'width') or changed(obj.size, 'height') then 
            calc_align(obj)
        end
    end
}