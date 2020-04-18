local _NAME = ...
local tween = require(_NAME..".tween")

Tween = GameObject:extend {
    easing = tween.easing;
    ms = false;
    init = function(self, duration, subject, target, easing, onFinish)
        GameObject.init(self, {classname='Tween'})
        easing = easing or 'linear'
        self.tween = tween.new(duration, subject, target, Tween.easing[easing])
        self.mod = 1
        self.onFinish = onFinish
        self:addUpdatable()
    end,
    complete = function(self)
        if self.onFinish then 
            self.onFinish()
            self:pause()
            self:set(0)
        end
    end,
    set = function(self, v)
        if self.tween:set(v) then 
            self:complete()
        end
    end,
    pause = function(self)
        self._old_mod = self.mod
        self.mod = 0
    end,
    resume = function(self)
        self.mod = self._old_mod or self.mod
    end,
    _update = function(self, dt)
        if Tween.ms then dt = dt * 1000 end
        if self.tween:update(dt * self.mod) then
            self:complete()
        end
    end
}