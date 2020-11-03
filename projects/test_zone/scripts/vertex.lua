local batch_grass = SpriteBatch{ file = 'grass.bmp' }

Grass = Entity{
  "Grass",
  -- image = 'grass.bmp',
  align = 'center',
  added = function(ent)
    ent.start_scale = ent.scale
    batch_grass:set(unpack(ent.pos))
  end,
  update = function(ent, dt)
    local mx, my = Camera("me").mouse()
    local mouse_dist = Math.distance(mx, my, ent.pos[1], ent.pos[2])
    local max_dist = 100

    if mouse_dist < max_dist then
      ent.scale = Math.lerp(ent.start_scale * 2, ent.start_scale, mouse_dist / max_dist)
    end
  end
}

State{
  "vertex",
  enter = function()	
    Input.set({
        left = {"left","a"},
        right = {"right","d"},
        up = {"up","w"},
        down = {"down","s"}
    })

    Camera("me",{ 
        view_x=(Game.width/2 - 100), view_y=(Game.height/2 - 100), 
        width=200,height=200--,crop=true 
    })

    for i=1,1000 do 
      Grass{
        pos={
          Math.random(0, Game.width),
          Math.random(0, Game.height)
        },
        scale=Math.random(1,3)
      }
    end 
  end,
  update = function(dt)
    local cam = Camera("me")
    local spd = 100
    if Input.pressed("left") then 
      cam.pos[1] = cam.pos[1] - spd * dt
    end
    if Input.pressed("right") then 
      cam.pos[1] = cam.pos[1] + spd * dt
    end

    if Input.pressed("up") then 
      cam.pos[2] = cam.pos[2] - spd * dt
    end
    if Input.pressed("down") then 
      cam.pos[2] = cam.pos[2] + spd * dt
    end
  end,
  draw = function()
    local mx, my = Camera("me").mouse()
    Draw.color('red')
    Draw.circle('fill',mx,my,8)
  end
}