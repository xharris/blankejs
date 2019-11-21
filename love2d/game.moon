import Entity, Game from require "blanke"

Game {
    res: 'data',
    load: () ->
        Game.spawn("Player")
}

Entity "Player", {
    image: 'soldier.png'
    update: (dt) =>
        @x += 5 * dt
}