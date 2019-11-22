io.stdout\setvbuf('no')
import Blanke from require "blanke"
require "game"

love.load = () -> Blanke.load!
love.update = (dt) -> Blanke.update dt
love.draw = () -> Blanke.draw!
love.keypressed = (key, scancode, isrepeat) -> Blanke.keypressed key, scancode, isrepeat
love.keyreleased = (key, scancode) -> Blanke.keyreleased key, scancode