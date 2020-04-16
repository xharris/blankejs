[Shader Variables](https://love2d.org/wiki/Shader_Variables)

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

`effect` effect code string, returns output color of pixel

> ```
> vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
>     vec4 pixel = Texel(texture, texture_coords);
>     -- effect code
>     return pixel * color;
> }
> ```

* in_color: set by Draw.color() or mesh color
* texture: image/canvas being drawn
* tex_coord: normalized texture coordinates. Ex (0, 1) is top right
* screen_coords: pixel coordinates. (0.5, 0.5) is top left, (0, 0) is center

`vertex` vertex code string, returns final position of vertex

> ```
> vec4 position(mat4 transform_projection, vec4 vertex_position) {
>     -- vertex code
>     return transform_projection * vertex_position;
> }
> ```     

* transform_project: transform matrix affected by Draw.translate/rotate/etc combined with ortho projection matrix
* vertex_position: un-transformed position of vetex

`code` full shader code string (overrides effect and vertex)

`use_canvas=true` NOTE: any effect that doesn't use the canvas cannot be chained with other effects

# Methods

`enable(name,...), disable(name,...)`

`set(effect_name, property, value)`

`send(effect_name, property, value)`

`sendVars(effect_name)`