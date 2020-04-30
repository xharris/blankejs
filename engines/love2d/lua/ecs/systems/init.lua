local _NAME = ...

Component{
    -- basic components
    pos             = { x = 0, y = 0 },

    -- drawing components
    quad            = { },
    size            = { width = 1, height = 1 },
    angle           = { 0 },
    scale           = { x = 1, y = 1 },
    offset          = { x = 0, y = 0 },
    shear           = { x = 0, y = 0 },
    blendmode       = { 'alpha' }
}

EcsUtil = {
    require_draw_components = function()
        return {'pos','quad','angle','size','scale','offset','shear','blendmode'}
    end,
    extract_draw_components = function(obj, override)
        override = override or {}
        local comps = {'pos','quad','angle','size','scale','offset','shear','blendmode'}
        for _, comp_name in ipairs(comps) do 
            extract(obj, comp_name, override[comp_name])
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
require(_NAME..".movement")
require(_NAME..".effect")

require(_NAME..".animation")
require(_NAME..".timer")
-- camera
-- audio?
-- map
-- physics
-- hitbox
-- net


local calc_align = function(obj)
    local align = obj[1] 
    local ax, ay = 0, 0
    if align then
        obj_entity = get_entity(obj)
        local size = obj_entity.size

        if string.contains(align, 'center') then
            ax = size.width/2 
            ay = size.height/2
        end
        if string.contains(align,'left') then
            ax = 0
        end
        if string.contains(align, 'right') then
            ax = size.width
        end
        if string.contains(align, 'top') then
            ay = 0
        end
        if string.contains(align, 'bottom') then
            ay = size.height
        end
        obj_entity.offset.x = floor(ax)
        obj_entity.offset.y = floor(ay)
    end
end

Component('align', { 'top left' })

System{
    component='align',
    requires={'size','offset'},
    add = function(obj)
        calc_align(obj)
        local obj_entity = get_entity(obj)
        track(obj_entity.align, 1)
        track(obj_entity.size, 'width')
        track(obj_entity.size, 'height')
    end,
    update = function(obj, dt)
        local obj_entity = get_entity(obj)
        if changed(obj_entity.align, 1) or 
            changed(obj_entity.size, 'width') or 
            changed(obj_entity.size, 'height') then 
                --print("changed",obj_entity.type,obj_entity.align[1],obj_entity.size.width,obj_entity.size.height)
            calc_align(obj)
        end
    end
}