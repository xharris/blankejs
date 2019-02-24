## Create a new shader 

`EffectManager.new{name, params, effect, vertex, shader, warp_effect}`

* **name** name of effect
* **params** list of variables that can be sent to shader. possible value types:
	* table (2 - 4 values)
	* number
	* boolean (gets converted to 1/0)
* **effect** string containing pixel shader code
* **vertex** string containing vertex shader code
* **shader** overwrites the entire shader template (effect + vertex)

## How effect/vertex works

```
float random(vec2 scale, vec2 gl_FragCoord, float seed) {
	/* use the fragment position for a different seed per-pixel */
	return fract(sin(dot(gl_FragCoord + seed, scale)) * 43758.5453 + seed);
}

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position) {
 		--[[ VERTEX CODE ]]-- 
		return transform_projection * vertex_position;
	}
#endif

#ifdef PIXEL
	vec4 effect(vec4 in_color, Image texture, vec2 texCoord, vec2 screen_coords){
		vec4 pixel = Texel(texture, texCoord);
		--[[ EFFECT CODE ]]--
		return pixel * in_color;
	}
#endif
```

## Variable types

* Love2D has it's own names for variable types in GLSL. Here are what they are converted to:

```
number 			--> float		
Image 			--> sampler2D	
extern 			--> uniform		
Texel 			--> texture2D	
pixel 			--> gl_FragColor
screen_coords 	--> gl_FragCoord.xy
```