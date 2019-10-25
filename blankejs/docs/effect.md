# Effects?

An Effect is a WebGL shader that uses GLSL 

# Creating a new effect 

`Effect.create(options)`

options:

* `name`
* `frag` fragment shader code
* `vert` vertex shader code
* `defaults` inputs for the shader (aka UNIFORMS)
* `set` checks value before it is sent to the shader. 
	* return nothing: the value will be passed to the shader
	* return false: this value is not sent to shader (skipped entirely)
	* return a value: new value is sent to shader

```
Effect.create({
	name: "my_effect",
	defaults: {val:0},
	set: {
		val: (v) => {
			if (v < 0)
				return 0;
		}
	}
	frag: `
varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec4 filterArea;
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

Basically it says:

* Set effect on GameObject

```
var bob = new Player(); // an Entity class
bob.effect = "zoomblur"
bob.effect.zoomblur.center = [Game.width/2, Game.height/2]
```

* Remove an effect

`bob.effect.zoomblur.destroy()`

# Convert from ShaderToy

mainImage ( ... ) -> main ( )

vec2 fragCoord = vTextureCoord;
[+] varying vec2 vTextureCoord; (at top)

vec4 fragColor;
gl_FragColor = fragColor; (at end)

iMouse - mouse coordinates, need to be passed in as a uniform

iResolution -> inputSize
[+] uniform vec4 inputSize;

iChannel -> can be `uSampler`
[+] uniform sampler2D uSampler;

texture(...) -> texture2D(...)

# Common Errors

## Loop index cannot be compared with non-constant expression

change `int i = 2;` to `const int i = 2;`