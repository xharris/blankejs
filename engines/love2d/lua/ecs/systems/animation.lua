local animation_props = { file='', name='', frame=1, speed=1 }
Component('anim', animation_props)
Component('animation', animation_props)

System{
  'anim', 'animation',
  add = function(obj)
    local anim = obj.anim or obj.animation
    
    -- obj.image = Image{use_size=false}
  end,
  update = function(obj, dt)

  end
}

--@global
Animation = callable{
  __call = function(opt)
    for _, anim in ipairs(opt) do 
      local o = function(k) return anim[k] or opt[k] end

      local path = o('path')
      local img, size = {width=0,height=0}
      if path then 
        img = Cache.get('Image', Game.res('image',o('path')), function(key)
            return love.graphics.newImage(key)
        end)
      end
      
      

    end
  end
}