import Entity, Game, Canvas, Input, Draw, Audio, Effect, Math, Map from require "blanke"
import is_object, p from require "moon"

Game {
    res: 'data'
    filter: 'nearest'
    load: () ->
        Game.setBackgroundColor(1,1,1,1)
        Map.load('level1.map')
        for i = 1,10
            Game.spawn("Box", { x: Math.random(-200,200), y: Math.random(-200,200) })
}

Map.config {
    tile_hitbox: { 'ground' },
    entities: { 'Player' }
}

Input {
    left: { "left", "a" }
    right: { "right", "d" }
    up: { "up", "w" }
    action: { 'space' }
}, { no_repeat: { "up" } }

Entity "Player", {
    image: 'soldier.png'
    scalex: 2,
    camera: {"player", "mini"},
    testdraw: {
        { color: {1, 0, 0, 0.5} },
        { line: {0, 0, Game.width/2, Game.height/2} }
    }
    update: (dt) =>
        hspeed = 100
        Camera.get("player").enabled = @x > 50
        if Input.pressed('right')
            @x += hspeed * dt
        if Input.pressed('left')
            @x -= hspeed * dt
        if Input.released('action')
            Audio.stop('fire.ogg')
        Camera.get("player").angle = (@x/Game.width)*90
    draw: (d) =>
        Draw {
            {'color', 1, 0, 0},
            {'line', @x, @y, Game.width/2, Game.height/2},
            {'color'}
        }
        d!
}