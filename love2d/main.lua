io.stdout:setvbuf('no')
Blanke = require "blanke"
require "game"

function love.load()
    Blanke.BlankeLoad()
end

function love.update(dt)
    Blanke.BlankeUpdate(dt)
end

function love.draw()
    Blanke.BlankeDraw()
end