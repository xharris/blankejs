Effect.new("bloom", {
    vars = { samples=5, quality=1 },
    integers = { 'samples' },
    effect = [[
  vec4 source = Texel(texture, texture_coords);
  vec4 sum = vec4(0);
  number diff = (samples - 1) / 2;
  vec2 sizeFactor = vec2(1) / love_ScreenSize.xy * quality;

  for (number x = -diff; x <= diff; x++)
  {
    for (number y = -diff; y <= diff; y++)
    {
      vec2 offset = vec2(x, y) * sizeFactor;
      sum += Texel(texture, texture_coords + offset);
    }
  }
  pixel = ((sum / (samples * samples)) + source);
  ]]
})

-- doesn't look the same as chromatic abberation, but looks better for gaming imo
Effect.new("chroma shift", {
    vars = { angle=0, radius=2, direction={0,0} },
    effect = [[
      vec2 tc = texture_coords;

      pixel.r = Texel(texture, vec2(tc.x + direction.x, tc.y - direction.y)).r;
      pixel.g = Texel(texture, vec2(tc.x, tc.y + direction.y)).g;
      pixel.b = Texel(texture, vec2(tc.x - direction.x, tc.y - direction.y)).b;
    ]],
    update = function(vars)
      dx = (math.cos(math.rad(vars.angle)) * vars.radius) / Game.width
      dy = (math.sin(math.rad(vars.angle)) * vars.radius) / Game.height
      vars.direction = {dx,dy}
    end
})

--[[
    blend = {"replace", "alphamultiply"},
      vec4 px_minus = Texel(texture, texture_coords - direction);
      vec4 px_plus = Texel(texture, texture_coords + direction);
      pixel = vec4(px_minus.r, pixel.g, px_plus.b, pixel.a);
      if ((px_minus.a == 0 || px_plus.a == 0) && pixel.a > 0) {
          pixel.a = 1.0;
      }
]]

Effect.new("zoom blur", {
  vars = { center={0,0}, strength=0.1 },
  effect = [[
    vec4 new_color = vec4(0.0);
    float total = 0.0;
    vec2 toCenter = center - texture_coords * tex_size;

    /* randomize the lookup values to hide the fixed number of samples */
    float offset = random(vec2(12.9898, 78.233), screen_coords, 0.0);

    for (float t = 0.0; t <= 40.0; t++) {
        float percent = (t + offset) / 40.0;
        float weight = 4.0 * (percent - percent * percent);
        vec4 sample = texture2D(texture, texture_coords + toCenter * percent * strength / tex_size);

        /* switch to pre-multiplied alpha to correctly blur transparent images */
        sample.rgb *= sample.a;

        new_color += sample * weight;
        total += weight;
    }

    pixel = new_color / total;

    /* switch back from pre-multiplied alpha */
    pixel.rgb /= pixel.a + 0.00001;
  ]]
})

-- UNTESTED
Effect.new('grayscale', {
  vars = { strength=1 },
  effect = [[
  number average = (pixel.r + pixel.b + pixel.g)/3.0;
  pixel.r = pixel.r + (average-pixel.r) * strength;
  pixel.g = pixel.g + (average-pixel.g) * strength;
  pixel.b = pixel.b + (average-pixel.b) * strength;
  ]]
})

-- DOES NOT WORK
Effect.new('warp sphere', {
  vars = { radius=50, strength=2, center={0,0} },
  effect = [[
    vec2 coord =  texture_coords * tex_size;
    coord -= center;
    float distance = length(coord);
    if (distance < radius) {
        float percent = distance / radius;
        if (strength > 0.0) {
            coord *= mix(1.0, smoothstep(0.0, radius / distance, percent), strength * 0.75);
        } else {
            coord *= mix(1.0, pow(percent, 1.0 + strength * 0.75) * radius / distance, 1.0 - percent);
        }
    }
    coord += center;
    gl_FragColor = texture2D(texture, coord / tex_size);
    vec2 clampedCoord = clamp(coord, vec2(0.0), tex_size);
    if (coord != clampedCoord) {
        gl_FragColor.a *= max(0.0, 1.0 - length(coord - clampedCoord));
    }
  ]]
})

Effect.new('static', {
  vars = { strength={5,0} },
  effect = [[
  vec2 new_tc = texture_coords;
  number off = random(vec2(0, 1.0), texture_coords, time);
  pixel = Texel(texture, vec2(
			texture_coords.x + getX(off - 1.0) * strength.x,
			texture_coords.y + getY(off - 1.0) * strength.y
    ));
  ]]
})

Effect.new('cosmic static', {
  vars = { strength={5,0} },
  effect = [[
  vec2 new_tc = texture_coords;
  number off = random(vec2(-1.0, 1.0), new_tc, time);
  pixel = Texel(texture, vec2(
			texture_coords.x + getX(off - 1.0) * strength.x,
			texture_coords.y + getY(off - 1.0) * strength.y
		));
  ]]
})

Effect.new("tv static", {
    vars = { x=5, y=5 },
    effect = [[
number off = random(vec2(x, y), texture_coords, time);
pixel = vec4(off, off, off, 1.0);
]]
})

Effect.new("scanlines", {
    vars={ edge={0.2, 0.8} },
	code= [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
	vec4 rgb = Texel(texture, texture_coords);
	vec4 intens = smoothstep(edge.x,edge.y,rgb) + normalize(vec4(rgb.xyz, 1.0));

	if (fract(pixel_coords.y * 0.5) > 0.5) intens = rgb * 0.8;
	intens.a = 1.0;
    return intens;
}
]]
})

Effect.new("crt", {
	vars = {
		--[[
			Controls the intensity of the barrel distortion used to emulate the
			curvature of a CRT. 0.0 is perfectly flat, 1.0 is annoyingly
			distorted, higher values are increasingly ridiculous.
		]]
		distortion=0.2,
		-- 	Simulate a CRT gamma of 2.4
		inputGamma=2.4,
		-- 	Compensate for the standard sRGB gamma of 2.2
		outputGamma=2.2,
        scan_weight=0.3
	},
    auto_vars=true,
	code= [[
/*
    CRT-simple shader
    Copyright (C) 2011 DOLLS. Based on cgwg's CRT shader.
    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
    modified by slime73 for use with love2d and mari0
*/

extern vec2 inputSize;
extern vec2 outputSize;
extern vec2 textureSize;


#define SCANLINES

// Enable screen curvature.
#define CURVATURE

// Macros.
#define TEX2D(c) pow(checkTexelBounds(texture, (c)), vec4(inputGamma))
#define PI 3.141592653589


vec2 bounds = vec2(inputSize.x / textureSize.x, 1.0 - inputSize.y / textureSize.y);

vec2 radialDistortion(vec2 coord, const vec2 ratio)
{
	float offsety = 1.0 - ratio.y;
	coord.y -= offsety;
	coord /= ratio;

	vec2 cc = coord - 0.5;
	float dist = dot(cc, cc) * distortion;
	vec2 result = coord + cc * (1.0 + dist) * dist;

	result *= ratio;
	result.y += offsety;

	return result;
}

#ifdef CURVATURE
vec4 checkTexelBounds(Image texture, vec2 coords)
{
	vec2 ss = step(coords, vec2(bounds.x, 1.0)) * step(vec2(0.0, bounds.y), coords);
	return Texel(texture, coords) * ss.x * ss.y;
}
#else
vec4 checkTexelBounds(Image texture, vec2 coords)
{
	return Texel(texture, coords);
}
#endif


/*
vec4 checkTexelBounds(Image texture, vec2 coords)
{
	vec2 bounds = vec2(inputSize.x / textureSize.x, 1.0 - inputSize.y / textureSize.y);
	vec4 color;
	if (coords.x > bounds.x || coords.x < 0.0 || coords.y > 1.0 || coords.y < bounds.y)
		color = vec4(0.0, 0.0, 0.0, 1.0);
	else
		color = Texel(texture, coords);
	return color;
}
*/


// Calculate the influence of a scanline on the current pixel.
//
// 'distance' is the distance in texture coordinates from the current
// pixel to the scanline in question.
// 'color' is the colour of the scanline at the horizontal location of
// the current pixel.
vec4 scanlineWeights(float distance, vec4 color)
{
	// The "width" of the scanline beam is set as 2*(1 + x^4) for
	// each RGB channel.
	vec4 wid = 2.0 + 2.0 * pow(color, vec4(4.0));

	// The "weights" lines basically specify the formula that gives
	// you the profile of the beam, i.e. the intensity as
	// a function of distance from the vertical center of the
	// scanline. In this case, it is gaussian if width=2, and
	// becomes nongaussian for larger widths. Ideally this should
	// be normalized so that the integral across the beam is
	// independent of its width. That is, for a narrower beam
	// "weights" should have a higher peak at the center of the
	// scanline than for a wider beam.
	vec4 weights = vec4(distance / scan_weight);
	return 1.4 * exp(-pow(weights * inversesqrt(0.5 * wid), wid)) / (0.6 + 0.2 * wid);
}

vec4 effect(vec4 vcolor, Image texture, vec2 texCoord, vec2 pixel_coords)
{
	vec2 one = 1.0 / textureSize;
	float mod_factor = texCoord.x * textureSize.x * outputSize.x / inputSize.x;


	// Here's a helpful diagram to keep in mind while trying to
	// understand the code:
	//
	//  |      |      |      |      |
	// -------------------------------
	//  |      |      |      |      |
	//  |  01  |  11  |  21  |  31  | <-- current scanline
	//  |      | @    |      |      |
	// -------------------------------
	//  |      |      |      |      |
	//  |  02  |  12  |  22  |  32  | <-- next scanline
	//  |      |      |      |      |
	// -------------------------------
	//  |      |      |      |      |
	//
	// Each character-cell represents a pixel on the output
	// surface, "@" represents the current pixel (always somewhere
	// in the bottom half of the current scan-line, or the top-half
	// of the next scanline). The grid of lines represents the
	// edges of the texels of the underlying texture.

	// Texture coordinates of the texel containing the active pixel.
#ifdef CURVATURE
	vec2 xy = radialDistortion(texCoord, inputSize / textureSize);
#else
	vec2 xy = texCoord;
#endif

#ifdef SCANLINES

	// Of all the pixels that are mapped onto the texel we are
	// currently rendering, which pixel are we currently rendering?
	vec2 ratio_scale = xy * textureSize - 0.5;
	vec2 uv_ratio = fract(ratio_scale);

	// Snap to the center of the underlying texel.
	xy.y = (floor(ratio_scale.y) + 0.5) / textureSize.y;

	// Calculate the effective colour of the current and next
	// scanlines at the horizontal location of the current pixel.
	vec4 col  = TEX2D(xy);
	vec4 col2 = TEX2D(xy + vec2(0.0, one.y));

	// Calculate the influence of the current and next scanlines on
	// the current pixel.
	vec4 weights  = scanlineWeights(uv_ratio.y, col);
	vec4 weights2 = scanlineWeights(1.0 - uv_ratio.y, col2);

	vec4 mul_res_f = (col * weights + col2 * weights2);
	vec3 mul_res  = mul_res_f.rgb;

#else
	vec3 mul_res_f = TEX2D(xy);
	vec3 mul_res = mul_res_f.rgb;

#endif

	// dot-mask emulation:
	// Output pixels are alternately tinted green and magenta.
	vec3 dotMaskWeights = mix(
	        vec3(1.0, 0.7, 1.0),
	        vec3(0.7, 1.0, 0.7),
	        floor(mod(mod_factor, 2.0))
	    );

	mul_res *= dotMaskWeights;

	return vec4(pow(mul_res, vec3(1.0 / outputGamma)), 1.0);
}
]]
})

Effect.new("curvature", {
	vars = { distortion=0.2 },
    auto_vars=true,
	code = [[
extern vec2 inputSize;
extern vec2 textureSize;

/*
#define f 0.6
#define ox 0.5
#define oy 0.5
#define scale 0.8
#define k1 0.7
#define k2 -0.5
vec2 barrelDistort(vec2 coord)
{
	vec2 xy = (coord - vec2(ox, oy))/vec2(f) * scale;

	vec2 r = vec2(sqrt(dot(xy, xy)));

	float r2 = float(r*r);

	float r4 = r2*r2;

	float coeff = (k1*r2 + k2*r4);

	return ((xy+xy*coeff) * f) + vec2(ox, oy);
}
*/
vec2 radialDistortion(vec2 coord, const vec2 ratio)
{
	float offsety = 1.0 - ratio.y;
	coord.y -= offsety;
	coord /= ratio;

	vec2 cc = coord - 0.5;
	float dist = dot(cc, cc) * distortion;
	vec2 result = coord + cc * (1.0 + dist) * dist;

	result *= ratio;
	result.y += offsety;

	return result;
}
/*
vec4 checkTexelBounds(Image texture, vec2 coords, vec2 bounds)
{
	vec4 color = Texel(texture, coords) *

	vec2 ss = step(coords, vec2(bounds.x, 1.0)) * step(vec2(0.0, bounds.y), coords);

	color.rgb *= ss.x * ss.y;
	color.a = step(color.a, ss.x * ss.y);

	return color;
}*/

vec4 checkTexelBounds(Image texture, vec2 coords, vec2 bounds)
{
	vec2 ss = step(coords, vec2(bounds.x, 1.0)) * step(vec2(0.0, bounds.y), coords);
	return Texel(texture, coords) * ss.x * ss.y;
}

/*
vec4 checkTexelBounds(Image texture, vec2 coords)
{
	vec2 bounds = vec2(inputSize.x / textureSize.x, 1.0 - inputSize.y / textureSize.y);

	vec4 color;
	if (coords.x > bounds.x || coords.x < 0.0 || coords.y > 1.0 || coords.y < bounds.y)
		color = vec4(0.0, 0.0, 0.0, 1.0);
	else
		color = Texel(texture, coords);

	return color;
}
*/

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
	vec2 coords = radialDistortion(texture_coords, inputSize / textureSize);

	vec4 texcolor = checkTexelBounds(texture, coords, vec2(inputSize.x / textureSize.x, 1.0 - inputSize.y / textureSize.y));
	texcolor.a = 1.0;

	return texcolor;
}
]]
})
