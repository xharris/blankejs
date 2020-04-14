Component('gravity', { v=0, direction=90 })

System{
  component='vel',
  requires={'pos'},
  update = function(obj, dt)
    if obj.vel.x ~= 0 then obj.pos.x = obj.pos.x + obj.vel.x * dt end 
    if obj.vel.y ~= 0 then obj.pos.y = obj.pos.y + obj.vel.y * dt end
  end
}

System{
  component='gravity',
  requires={'vel'},
  update=function(obj, dt)
    if obj.gravity.v ~= 0 then 
      local gravx, gravy = Math.getXY(obj.gravity.direction, obj.gravity.v)
      obj.vel.x = obj.vel.x + gravx
      obj.vel.y = obj.vel.y + gravy
    end
  end
}