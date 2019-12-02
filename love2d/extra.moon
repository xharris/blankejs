-- EFFECTS

Effect.new "bloom", {
    vars: { samples: 5, quality: 1 },
    integers: { 'samples' }
    effect: "
  vec4 source = Texel(texture, texCoord);
  vec4 sum = vec4(0);
  int diff = (samples - 1) / 2;
  vec2 sizeFactor = vec2(1) / love_ScreenSize.xy * quality;
  
  for (int x = -diff; x <= diff; x++)
  {
    for (int y = -diff; y <= diff; y++)
    {
      vec2 offset = vec2(x, y) * sizeFactor;
      sum += Texel(texture, texCoord + offset);
    }
  }
  
  pixel = ((sum / (samples * samples)) + source);    
    "
}

Effect.new "chroma shift", {
    vars: { angle:0, radius:2, direction:{0,0} },
    blend: {"replace", "alphamultiply"},
    effect: "
        pixel = pixel * vec4(
        Texel(texture, texCoord - direction).r,
        Texel(texture, texCoord).g,
        Texel(texture, texCoord + direction).b,
        1.0);
    ",
    draw: (vars, applyShader) ->
        {:angle, :radius} = vars
        dx = (math.cos(math.rad(angle)) * radius) / Game.width
        dy = (math.sin(math.rad(angle)) * radius) / Game.height
        vars.direction = {dx,dy}
}

-- HC STUFF

entity:new: () =>
  ... 

        -- hitbox
        if args.hitboxes
            @hbList = {}
            for name, info in pairs(args.hitboxes)
                shape = info
                if type(info) == 'string'
                    @addHitbox(name, info)
                else
                    @addHitbox(name, unpack(info))

entity:_update: =>
  ...
        -- hitbox collisions
        for name, hb in pairs(@hbList)
            hb\move(dx*dt, dy*dt)
            if @collision and @collision[name]
                hb\collisions (other, vec) -> 
                    @collisionStopX = () =>
                        dx = 0
                        hb\move(vec.x,0)
                    @collisionStopY = () =>
                        dy = 0
                        hb\move(0,vec.y)
                    @collisionStop = () =>
                        dx, dy = 0, 0
                        hb\move(vec.x,vec.y)
                    @collision[name](@,other,vec)
        if @main_hitbox
            @x, @y = @hbList[@main_hitbox]\center()
  ...

entity:_draw: =>
  ...

        if @hitboxes
            for name, hb in pairs(@hbList)
                hb\draw!

map:addTile: =>
  ...
        -- hitbox?
        hb_name = if options.tile_hitbox then options.tile_hitbox[string.gsub(FS.basename(file), '.'..FS.extname(file), '')]
        if hb_name
            table.insert(@hbList, Hitbox('rect',{x,y,tw,th},hb_name))

entity:addHitbox: (name, shape, dims, tag) =>
        if not @hbList then @hbList = {}

        if not dims
            if shape == 'rect' then dims = { 0, 0, @width, @height }
            if shape == 'circle' then dims = { 0, 0, math.max(@width,@height) }
        if not tag
            tag = name

            
        @hb = Hitbox(shape, dims, tag)
        @hb.parent = @
        @hb.offx = dims[1] * @scalex * @scale
        @hb.offy = dims[2] * @scaley * @scale
        @hb\moveTo @x, @y
        if not @hbList[main_hitbox]
            @main_hitbox = name
        @hbList[name] = @hb



export class Hitbox extends GameObject
    translate = { rect: 'rectangle' }

    @at: (x,y) -> HC.shapesAt(x,y)   

    @test: (x,y,tag) ->
        boxes = Hitbox.at(x,y)
        for hb in *boxes
            if hb.tag == tag then return true 
        return false

    new: (shape,dims,tag) =>
        super!
        shape = translate[shape] or shape
        @hb = HC[shape](unpack(dims))
        @hb.ref = @
        @hb.tag = tag
        @offx = 0
        @offy = 0
    scaleTo: (s) => 
        if @_last_scale then 
            @hb\scale 1/@_last_scale
        @hb\scale s
        @_last_scale = s
    move: (x,y) => @hb\move(x,y)
    moveTo: (x,y) => @hb\moveTo(x + @offx,y + @offy)
    center: () => @hb\center!
    collisions: (fn) =>
        for shape, delta in pairs(HC.collisions(@hb))
            fn shape, delta
    _draw: () =>
        Draw.stack () ->
            Draw.color(1,0,0,0.25)
            @hb\draw('fill')