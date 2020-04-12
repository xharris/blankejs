Component('gravity', { v=0, direction=90 })

System{
  'gravity', 'vel',
  add=function(obj)
    extract(obj, 'pos')
    extract(obj, 'vel')
    extract(obj, 'gravity')
  end,
  update=function(obj, dt)
    if obj.gravity.v > 0 then 
      local gravx, gravy = Math.getXY(obj.gravity.direction, obj.gravity.v)
      obj.vel.x = obj.vel.x + gravx
      obj.vel.y = obj.vel.y + gravy
    end
    obj.pos.x = obj.pos.x + obj.vel.x * dt
    obj.pos.y = obj.pos.y + obj.vel.y * dt
  end
}