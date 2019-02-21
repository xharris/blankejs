
-- Creating a new shader effect
EffectManager.new{name, params, effect, vertex, shader, warp_effect}
--[[
	name: name of effect
	params: list of variables that can be sent to shader
		table (vec2, vec3, vec4)
		number
		boolean (converted to 1/0)
	use_canvas: canvases seem best used when the shader affects everything on screen (as opposed to just one entity)
	effect: string containing pixel shader code
	vertex: string containing vertex shader code
	shader: completely custom shader code (not wrapped in built-in code)
	warp_effect: if the effect is a warp effect (default: false)

-- Shader string if 'shader' arg is not supplied: 

/* From glfx.js : https://github.com/evanw/glfx.js */
float random(vec2 scale, vec2 gl_FragCoord, float seed) {
	/* use the fragment position for a different seed per-pixel */
	return fract(sin(dot(gl_FragCoord + seed, scale)) * 43758.5453 + seed);
}

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position) {
 		<-- VERTEX CODE --> 
		return transform_projection * vertex_position;
	}
#endif

#ifdef PIXEL
	vec4 effect(vec4 in_color, Image texture, vec2 texCoord, vec2 screen_coords){
		vec4 pixel = Texel(texture, texCoord);
		<-- PIXEL CODE -->
		return pixel * in_color;
	}
#endif

-- If warp_effect is true, <-- PIXEL CODE --> is also wrapped in this:

		vec2 coord =  texCoord * texSize;
		<-- PIXEL CODE -->
		gl_FragColor = texture2D(texture, coord / texSize);
		vec2 clampedCoord = clamp(coord, vec2(0.0), texSize);
		if (coord != clampedCoord) {
			gl_FragColor.a *= max(0.0, 1.0 - length(coord - clampedCoord));
		}

Most GLSL code should work as some keywords are converted:
	float			--> number
	sampler2D		--> Image
	uniform			--> extern
	texture2D		--> Texel
	gl_FragColor	--> pixel
	gl_FragCoord.xy --> screen_coords
These are converted in vertex/pixel/shader code as well.
]]		

-- Using a shader effect
my_effect = Effect(name)
--[[
Built-in effects and their params:
	chroma shift
		num angle = 0	(degrees)
		num radius = 4
		vec2 direction = {0, 0}
	zoom blur
		vec2 center = {0, 0}
		num strength = 0.3
	warp sphere
		num radius = 50
		num strength = -2
		vec2 center = {0, 0}
	grayscale
		num factor = 1
]]

-- instance methods
send(var_name, value)		-- send a parameter to the shader
draw(func)					-- draw shader and affect any draw operations in func()

-- Example:
function state:enter()
	my_effect = Effect("zoom blur")
end

function state:draw()
	my_effect:send("center", {mouse_x, mouse_y})
	my_effect:draw(function()
		my_scene:draw()
	end)
end
