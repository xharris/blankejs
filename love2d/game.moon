import Entity, Game, Canvas from require "blanke"
import is_object, p from require "moon"

local bob, my_canv

Game {
    res: 'data',
    filter: 'nearest'
    load: () ->
        bob = Game.spawn("Player")
}

Entity "Player", {
    image: 'soldier.png'
    canv: Canvas
    update: (dt) =>
        @x += 5 * dt
        @canv.scalex += 2 * dt
        @canv\drawTo(@)
    draw: false
}

Entity "FakePlayer", {
    image: 'soldier.png'
    spawn: () =>
        @x = Game.width / 2
}