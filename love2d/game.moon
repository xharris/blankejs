import Entity, Game, Canvas, Input from require "blanke"
import is_object, p from require "moon"

Game {
    res: 'data'
    filter: 'nearest'
    load: () ->
        bob = Game.spawn("Player")
}

Input {
    left: { "left", "a" }
    right: { "right", "d" }
    up: { "up", "w" }
}, { no_repeat: { "up" } }

Entity "Player", {
    image: 'soldier.png'
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