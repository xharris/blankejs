io.stdout\setvbuf('no')
import BlankeLoad, BlankeUpdate, BlankeDraw from require "blanke"
require "game"

love.load = () -> BlankeLoad()
love.update = (dt) -> BlankeUpdate(dt)
love.draw = () -> BlankeDraw()