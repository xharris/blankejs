# Effects?

An Effect is a WebGL shader that uses GLSL 

# Creating a new effect 

`Effect.create(options)`

options:

* `name`
* `frag` fragment shader code
* `vert` vertex shader code
* `defaults`

```
Effect.create({
	name: "my_effect",
	defaults: {val:0},
	frag: `
varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform float val;

void main(void)
{
	gl_FragColor = texture2D(uSampler, vTextureCoord);
	gl_FragColor.r = val;
}
`
})
```

# Using an effect

Go to the docs for General / BlankE > GameObject > Properties (effect)