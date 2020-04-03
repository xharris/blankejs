-- basic components
Component{
    position        = { x = 0, y = 0 },
    size            = { width = 0, height = 0 },
    velocity        = { x = 0, y = 0 }
}

--CANVAS
require 'systems.canvas'

--IMAGE
do 
    Component('image', { index=nil, align='top left' } )
    System{
        'animation', 'image',
        add = function(obj)

        end,
        update = function(dt)

        end,
        draw = function(obj)
            if not (obj.animation or obj.image) then return true end

            if obj.animation then 

            end
            if obj.image then 

            end
        end
    }

    Image = callable {
        __call = function(_)

        end,
        animation = function()

        end
    }
end

--PLATFORMER PHYSICS
Component('platformer', { gravity = 0, gravity_direction = 90 })

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
