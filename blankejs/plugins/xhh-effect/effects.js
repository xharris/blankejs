document.addEventListener('blankeLoaded', (e) => {
    let { Effect, Game } = e.detail.Blanke;

    // zoomblur: center [x,y]
    Effect.create({
        name: "zoomblur",
        defaults: { center: [0, 0] },
        frag:`
precision highp float;
varying vec2 vTextureCoord;

uniform sampler2D uSampler;
uniform vec2 center;
uniform vec4 inputSize;
uniform vec4 outputFrame;
uniform float time;

#define focusDetail 7

void main() {
	float focusPower = 10.0;

    vec2 fragCoord = vTextureCoord;

    vec2 uv = fragCoord.xy;
    vec2 mousePos = (center.xy - outputFrame.xy) / inputSize.xy; // same as * inputSize.zw
	vec2 focus = uv - mousePos;
    
    vec4 outColor;
    outColor = vec4(0, 0, 0, 0);

    for (int i=0; i<focusDetail; i++) {
        float power = 1.0 - focusPower * (1.0/inputSize.x) * float(i);
        vec4 c = texture2D(uSampler, focus * power + mousePos).rgba;
        if (texture2D(uSampler, focus * power + mousePos).a > 0.0)
            outColor.rgba += c;
        else
            outColor.rgb += c.rgb;
    }
    
    outColor.rgba *= 1.0 / float(focusDetail);

	gl_FragColor = outColor;
}
`})

    // ascii
    Effect.create({
			name: "ascii",
            defaults: { pixelSize: 8, frame: [0,0,1,1] },
            frag: `
varying vec2 vTextureCoord;

uniform vec4 frame;
uniform float pixelSize;
uniform sampler2D uSampler;

vec2 mapCoord( vec2 coord )
{
    coord *= frame.xy;
    coord += frame.zw;

    return coord;
}

vec2 unmapCoord( vec2 coord )
{
    coord -= frame.zw;
    coord /= frame.xy;

    return coord;
}

vec2 pixelate(vec2 coord, vec2 size)
{
    return floor( coord / size ) * size;
}

vec2 getMod(vec2 coord, vec2 size)
{
    return mod( coord , size) / size;
}

float character(float n, vec2 p)
{
    p = floor(p*vec2(4.0, -4.0) + 2.5);

    if (clamp(p.x, 0.0, 4.0) == p.x)
    {
        if (clamp(p.y, 0.0, 4.0) == p.y)
        {
            if (int(mod(n/exp2(p.x + 5.0*p.y), 2.0)) == 1) return 1.0;
        }
    }
    return 0.0;
}

void main()
{
    vec2 coord = mapCoord(vTextureCoord);

    // get the rounded color..
    vec2 pixCoord = pixelate(coord, vec2(pixelSize));
    pixCoord = unmapCoord(pixCoord);

    vec4 color = texture2D(uSampler, pixCoord);

    // determine the character to use
    float gray = (color.r + color.g + color.b) / 3.0;

    float n =  65536.0;             // .
    if (gray > 0.2) n = 65600.0;    // :
    if (gray > 0.3) n = 332772.0;   // *
    if (gray > 0.4) n = 15255086.0; // o
    if (gray > 0.5) n = 23385164.0; // &
    if (gray > 0.6) n = 15252014.0; // 8
    if (gray > 0.7) n = 13199452.0; // @
    if (gray > 0.8) n = 11512810.0; // #

    // get the mod..
    vec2 modd = getMod(coord, vec2(pixelSize));

    gl_FragColor = color * character( n, vec2(-1.0) + modd * 2.0);

}
`})
})