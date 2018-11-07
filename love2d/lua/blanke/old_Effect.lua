local moonshine = blanke_require("extra.moonshine")

Effect = Class{
    init = function(self, name)
        self.effect = moonshine(moonshine.effects[name])
    end,
    chain = function(self, ...)
        self.effect.chain(...)
        return self
    end,
    draw = function(self, fn)
        self.effect(fn)
    end 
}

return Effect