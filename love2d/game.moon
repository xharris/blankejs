import Entity, Game, Canvas, Input, Draw from require "blanke"
import is_object, p from require "moon"

Game {
    res: 'data'
    filter: 'nearest'
    load: () ->
        Game.spawn("Player")
    draw: () ->
        Draw {
            {'color', 1, 0, 0},
            {'line', 0, 0, Game.width/2, Game.height/2},
            {'color'}
        }
}

Input {
    left: { "left", "a" }
    right: { "right", "d" }
    up: { "up", "w" }
}, { no_repeat: { "up" } }

Entity "Player", {
    image: 'soldier.png'
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
}

Entity "FakePlayer", {
    image: 'soldier.png'
    spawn: () =>
        @x = Game.width / 2
}