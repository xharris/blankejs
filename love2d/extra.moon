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