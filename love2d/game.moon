import Entity, Game, new from require "blanke"

Entity "Player", {
    image: 'soldier.png'
}

Game {
    res: 'data',
    load: () ->
        Game.spawn("Player")
}