import Entity, Game, new from require "blanke"

Entity "Player", {
    image: 'soldier.png'
    update: (dt) =>
        print dt
}

Game {
    res: 'data',
    load: () ->
        Game.spawn("Player")
}