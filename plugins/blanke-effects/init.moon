Effect.new "bloom", {
    vars: { samples: 5, quality: 1 },
    integers: { 'samples' }
    effect: "
  vec4 source = Texel(texture, texCoord);
  vec4 sum = vec4(0);
  int diff = (samples - 1) / 2;
  vec2 sizeFactor = vec2(1) / love_ScreenSize.xy * quality;
  
  for (int x = -diff; x <= diff; x++)
  {
    for (int y = -diff; y <= diff; y++)
    {
      vec2 offset = vec2(x, y) * sizeFactor;
      sum += Texel(texture, texCoord + offset);
    }
  }
  
  pixel = ((sum / (samples * samples)) + source);    
    "
}

Effect.new "chroma shift", {
    vars: { angle:0, radius:2, direction:{0,0} },
    blend: {"replace", "alphamultiply"},
    effect: "
        pixel = pixel * vec4(
        Texel(texture, texCoord - direction).r,
        Texel(texture, texCoord).g,
        Texel(texture, texCoord + direction).b,
        1.0);
    ",
    draw: (vars, applyShader) ->
        {:angle, :radius} = vars
        dx = (math.cos(math.rad(angle)) * radius) / Game.width
        dy = (math.sin(math.rad(angle)) * radius) / Game.height
        vars.direction = {dx,dy}
}