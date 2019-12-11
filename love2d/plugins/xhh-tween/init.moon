tween = require "xhh-tween.tween"

export class Tween extends GameObject
    @easing: tween.easing
    @ms: false
    new: (duration, subject, target, easing='linear', onFinish) =>
        @tween = tween.new(duration, subject, target, tween.easing[easing])
        @mod = 1
        @onFinish = onFinish
        @addUpdatable!

    update: (dt) =>
        if Tween.ms then dt *= 1000
        if @tween\update dt * @mod
            if @onFinish then @onFinish!
            @remUpdatable!

{ :Tween }