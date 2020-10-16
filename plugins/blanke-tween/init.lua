local tween = require("plugins.xhh-tween.tween")

local complete = function(ent)
    ent.tween:set(ent.duration)
    if ent.onFinish then 
        ent.onFinish()
        ent:pause()
        ent:set(0)
    end
end

Tween = Entity("xhh-tween", {
    added = function(ent, args)
        local duration, subject, target, onFinish, easing = unpack(args)
        
        easing = easing or 'linear'
        ent.tween = tween.new(duration, subject, target, Tween.easing[easing])
        ent.duration = duration
        ent.mod = 1
        ent.onFinish = onFinish
    end,
    update = function(ent, dt)
        if Tween.ms then dt = dt * 1000 end
        if ent.tween:update(dt * ent.mod) then
            complete(ent)
        end
    end,
    set = function(self, v)
        if self.tween:set(v) then 
            complete(self)
        end
    end,
    pause = function(self)
        self._old_mod = self.mod
        self.mod = 0
    end,
    resume = function(self)
        self.mod = self._old_mod or self.mod
    end
})

Tween.ms = false
Tween.easing = tween.easing