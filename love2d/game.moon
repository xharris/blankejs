import Entity, Game, Canvas, Input, Draw, Audio, Effect from require "blanke"
import is_object, p from require "moon"

local eff

Game {
    res: 'data'
    filter: 'nearest'
    load: () ->
        Game.setBackgroundColor(1,1,1,1)
        Game.spawn("Player")
        eff = Effect "chroma shift"
    draw: (d) ->
        --eff\set "chroma shift", "radius", (love.mouse.getX() / Game.width) * 20
        --eff\draw () ->
        Draw.color(0,1,0)
        Draw.rect('fill',50,50,200,200)
        Draw.color()
        d!
}

Audio 'fire.ogg', {
    looping: false,
    volume: 0.2
}

    -- vec4 px_minus = Texel(texture, texCoord - direction);
    --     vec4 px_plus = Texel(texture, texCoord + direction);
    --     pixel = vec4(px_minus.r, pixel.g, px_plus.b, pixel.a);
    --     if ((px_minus.a == 0 || px_plus.a == 0) && pixel.a > 0) {
    --         pixel.a = 1.0;
    --     }
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

Input {
    left: { "left", "a" }
    right: { "right", "d" }
    up: { "up", "w" }
    action: { 'space' }
}, { no_repeat: { "up" } }

Entity "Player", {
    image: 'soldier.png'
    scalex: 4,
    testdraw: {
        { color: {1, 0, 0, 0.5} },
        { line: {0, 0, Game.width/2, Game.height/2} }
    }
    update: (dt) =>
        hspeed = 20
        if Input.pressed('right')
            @x += hspeed * dt
        if Input.pressed('left')
            @x -= hspeed * dt
        if Input.released('action')
            Audio.stop('fire.ogg')
    draw: (d) =>
        Draw {
            {'color', 1, 0, 0},
            {'line', @x, @y, Game.width/2, Game.height/2},
            {'color'}
        }
        d!
}

Entity "FakePlayer", {
    image: 'soldier.png'
    spawn: () =>
        @x = Game.width / 2
}