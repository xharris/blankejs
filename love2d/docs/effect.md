## Effect - GameObject (Updatable)

```
Effect.new("chroma shift", {
    vars = { angle=0, radius=2, direction={0,0} },
    blend = {"replace", "alphamultiply"},
    effect = "
        pixel = pixel * vec4(
        Texel(texture, texCoord - direction).r,
        Texel(texture, texCoord).g,
        Texel(texture, texCoord + direction).b,
        1.0);
    ",
    draw = function(vars, applyShader)
        dx = (math.cos(math.rad(vars.angle)) * vars.radius) / Game.width
        dy = (math.sin(math.rad(vars.angle)) * vars.radius) / Game.height
        vars.direction = {dx,dy}
    end
})

my_entity:setEffect('chroma shift')
my_entity.effect:set('chroma shift', 'radius', 4)
```

# Props

`vars` { effect_name: { prop1: value } }

# Methods

`enable(name,...), disable(name,...)`

`set(effect_name, property, value)`

`send(effect_name, property, value)`

`sendVars(effect_name)`