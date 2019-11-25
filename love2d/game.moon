import Entity, Game, Canvas, Input, Draw, Audio, Effect, Math from require "blanke"
import is_object, p from require "moon"

local eff

Game {
    res: 'data'
    filter: 'nearest'
    load: () ->
        Game.setBackgroundColor(1,1,1,1)
        Game.spawn("Player")
        for i = 1,10
            Game.spawn("Box", { x: Math.random(-200,200), y: Math.random(-200,200) })
    postDraw: () ->
        Draw {
            { 'color', 0,0,0 }
            { 'rect', 'line', 2, 2, Game.width-4, Game.height-4}
            {'color'}
        }
}

Audio 'fire.ogg', {
    looping: false,
    volume: 0.2
}

Input {
    left: { "left", "a" }
    right: { "right", "d" }
    up: { "up", "w" }
    action: { 'space' }
}, { no_repeat: { "up" } }

Camera "player", { scalex: 2, left: 0, top: 0, width: Image('soldier.png').width*4, height: Image('soldier.png').height*4 }
Camera "mini", { scalex: 1, left: 200, top:200, width: 600, height: 300}

Entity "Box", {
    draw: (d) =>
        Draw {
            { 'color', 1, 0, 0 },
            { 'rect', 'fill', @x, @y, 50, 50 },
            { 'color' }
        }
}

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

Entity "FakePlayer", {
    image: 'soldier.png'
    spawn: () =>
        @x = Game.width / 2
}