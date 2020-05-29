Component('vel', { x=0, y=0 })
Component('gravity', { v=0, direction=90 })

System{
  component='vel',
  requires={'pos'},
  update = function(obj, dt)
    local obj_entity = get_entity(obj)
    if obj.x ~= 0 then obj_entity.pos.x = obj_entity.pos.x + obj.x * dt end 
    if obj.y ~= 0 then obj_entity.pos.y = obj_entity.pos.y + obj.y * dt end
  end
}

System{
  component='gravity',
  requires={'vel'},
  update=function(obj, dt)
    local obj_entity = get_entity(obj)
    if obj.v ~= 0 then 
      local gravx, gravy = Math.getXY(obj.direction, obj.v)
      obj_entity.vel.x = obj_entity.vel.x + gravx
      obj_entity.vel.y = obj_entity.vel.y + gravy
    end
  end
}