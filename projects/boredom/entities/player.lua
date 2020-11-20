Image.animation('player_stand.png')
Image.animation('player_dead.png')
Image.animation('player_walk.png', { { rows=1, cols=2, duration=0.08 } })

Entity{
  "Player",
  camera = 'player',
  image = 'player_stand',
  align = "center",
  gravity = 10,
  can_jump = true,
  hitbox = { 
    tag='living',
    rect={5, 14, 10, 30}
  },
  vel = {0,0},
  collision = function(self, i, other_tag)
    if other_tag == 'death' then
      self:die()
    end
    if other_tag == 'ground' then
      if i.normal.y < 0 then
        self.can_jump = true
      end
      if i.normal.y ~= 0 then 
        self.vel[2] = 0
      end
    end
  end, 
  die = function(self)
    if not self.dead then
      self.dead = true
      self.image.name = "player_dead"
      self.hitbox.rect = {5, 14, 12, 30}

      Tween(1, self, { vel={0,0} }, function()
        State.restart('play')
      end)
    end
  end,
  update = function(self, dt)
    if not self.dead then
      -- left/right
      dx = 140
      self.vel[1] = 0
      if Input.pressed('right') then
        self.vel[1] = dx
        self.scalex = 1
      end
      if Input.pressed('left') then
        self.vel[1] = -dx
        self.scalex = -1
      end
      if Input.pressed('right') or Input.pressed('left') then
        self.image.name = 'player_walk'
      else
        self.image.name = 'player_stand'
      end
      -- jumping
      if Input.pressed('jump') and self.can_jump then
        self.vel[2] = -350
        self.can_jump = false
      end

      self.image.speed = 1
      if not Hitbox.at(self, 0,1,'ground') then
        self.image.name = 'player_walk'
        self.image.speed = 0
        self.image.frame_index = 2
      end
    end
  end
}