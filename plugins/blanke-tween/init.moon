tween = require "xhh-tween.tween"

export class Tween extends GameObject
    new: (duration, subject, target, easing='linear', onFinish) =>
        @tween = tween.new(duration, subject, target, tween.easing[easing])
        @onFinish = onFinish
        @addUpdatable!
        @destroy!

    update: (dt) =>
        if @tween\update dt
            if @onFinish then @onFinish!
            @destroy!

{ :Tween }