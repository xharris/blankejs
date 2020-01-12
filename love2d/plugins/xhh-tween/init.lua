local tween = require "xhh-tween.tween"

Tween = GameObject:extend {
    easing = tween.easing;
    ms = false;
    init = function(self, duration, subject, target, easing, onFinish)
        easing = easing or 'linear'
        self.tween = tween.new(duration, subject, target, tween.easing[easing])
        self.mod = 1
        self.onFinish = onFinish
        self:addUpdatable()
    end;
    update = function(self, dt)
        if Tween.ms then dt = dt * 1000 end
        if self.tween:update(dt * self.mod) then
            if self.onFinish then self.onFinish() end
            self:remUpdatable()
        end
    end;
}