document.addEventListener('blankeLoaded', (e) => {
    let { Effect } = e.detail.Blanke;

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
			defaults: { pixelSize: 8 },
			frag: 
`#version 300 es
varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec4 inputSize;

float round(float x) { return floor(x + 0.5); }

float character(int n, vec2 p)
{
	p = floor(p*vec2(4.0, -4.0) + 2.5);
    if (clamp(p.x, 0.0, 4.0) == p.x)
	{
        if (clamp(p.y, 0.0, 4.0) == p.y)	
		{
        	int a = int(round(p.x) + 5.0 * round(p.y));
			if (((n >> a) & 1) == 1) return 1.0;
		}	
    }
	return 0.0;
}

void main()
{
    vec2 fragCoord = vTextureCoord;
    vec4 fragColor;

	vec2 pix = fragCoord.xy;
	vec3 col = texture2D(uSampler, floor(pix/8.0)*8.0/inputSize.xy).rgb;	
	
	float gray = 0.3 * col.r + 0.59 * col.g + 0.11 * col.b;
	
	int n =  4096;                // .
	if (gray > 0.2) n = 65600;    // :
	if (gray > 0.3) n = 332772;   // *
	if (gray > 0.4) n = 15255086; // o 
	if (gray > 0.5) n = 23385164; // &
	if (gray > 0.6) n = 15252014; // 8
	if (gray > 0.7) n = 13199452; // @
	if (gray > 0.8) n = 11512810; // #
	
	vec2 p = mod(pix/4.0, 2.0) - vec2(1.0);
    
	// if (iMouse.z > 0.5)	col = gray*vec3(character(n, p));
	else col = col*character(n, p);
	
	fragColor = vec4(col, 1.0);
    gl_FragColor = fragColor;
}
`})
})