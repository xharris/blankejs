Effect.new("bloom", {
    vars = { samples=5, quality=1 },
    integers = { 'samples' },
    effect = [[
  vec4 source = Texel(texture, texture_coords);
  vec4 sum = vec4(0);
  int diff = (samples - 1) / 2;
  vec2 sizeFactor = vec2(1) / love_ScreenSize.xy * quality;
  
  for (int x = -diff; x <= diff; x++)
  {
    for (int y = -diff; y <= diff; y++)
    {
      vec2 offset = vec2(x, y) * sizeFactor;
      sum += Texel(texture, texture_coords + offset);
    }
  }
  pixel = ((sum / (samples * samples)) + source);
  ]]
})

Effect.new("chroma shift", {
    vars = { angle=0, radius=2, direction={0,0} },
    effect = [[
      vec2 tc = texture_coords;
      // fake chromatic aberration
      float sx = direction.x;///love_ScreenSize.x;
      float sy = direction.y;///love_ScreenSize.y;
      vec4 r = Texel(texture, vec2(tc.x + sx, tc.y + sy));
      vec4 g = Texel(texture, vec2(tc.x , tc.y + sy));
      vec4 b = Texel(texture, vec2(tc.x - sx, tc.y - sy));
      number a = (r.a + g.a + b.a)/3.0;
  
      return vec4(r.r, g.g, b.b, a);
    ]],
    draw = function(vars)
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
    
    gl_FragColor = new_color / total;
    
    /* switch back from pre-multiplied alpha */
    gl_FragColor.rgb /= gl_FragColor.a + 0.00001;
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
  vars = { strength={5,5} },
  effect = [[
  pixel = Texel(texture, vec2(
			texture_coords.x + getX(random(vec2(0, 2.0), screen_coords, time) - 1.0) * strength.x,
			texture_coords.y + getY(random(vec2(0, 2.0), screen_coords, time) - 1.0) * strength.y
		));
  ]]
})