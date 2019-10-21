document.addEventListener('blankeLoaded', (e) => {
    let { Effect } = e.detail.Blanke;

    Effect.create({
        name: "simple",
        frag:`
varying vec2 vTextureCoord;
uniform vec2 inputSize;
uniform sampler2D uSampler;
uniform vec4 filterArea;

void main(void) {
    vec2 new_coord = vec2(vTextureCoord.x + (sin() / filterArea.x), vTextureCoord.y);
    gl_FragColor = texture2D(uSampler, new_coord);
}
`})

    Effect.create({
        name: "otherblur",
        frag:`

        vec3 deform( in vec2 p )
        {
            vec2 q = sin( vec2(1.1,1.2)*iTime + p );
        
            float a = atan( q.y, q.x );
            float r = sqrt( dot(q,q) );
        
            vec2 uv = p*sqrt(1.0+r*r);
            uv += sin( vec2(0.0,0.6) + vec2(1.0,1.1)*iTime);
                 
            return texture( iChannel0, uv*0.3).yxx;
        }
        
        void main( out vec4 fragColor, in vec2 fragCoord )
        {
            vec2 p = -1.0 + 2.0*fragCoord/iResolution.xy;
        
            vec3  col = vec3(0.0);
            vec2  d = (vec2(0.0,0.0)-p)/64.0;
            float w = 1.0;
            vec2  s = p;
            for( int i=0; i<64; i++ )
            {
                vec3 res = deform( s );
                col += w*smoothstep( 0.0, 1.0, res );
                w *= .99;
                s += d;
            }
            col = col * 3.5 / 64.0;
        
            gl_FragColor = vec4( col, 1.0 );
        }        
`})

    Effect.create({
        name: "zoomblur",
        defaults: { center: [0, 0], strength: 0.5, innerRadius: 0, radius: -1 },
        set: {
            radius: (v) => {
                if (v < 0 || v === Infinity) {
                    return -1;
                }
            }
        },
        frag:`
varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec2 inputSize;

uniform vec2 center;
uniform float strength;
uniform float innerRadius;
uniform float radius;

const float MAX_KERNEL_SIZE = 32.0;

// author: http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/
highp float rand(vec2 co, float seed) {
    const highp float a = 12.9898, b = 78.233, c = 43758.5453;
    highp float dt = dot(co + seed, vec2(a, b)), sn = mod(dt, 3.14159);
    return fract(sin(sn) * c + seed);
}

void main() {

    float minGradient = innerRadius * 0.3;
    float innerRadius = (innerRadius + minGradient * 0.5) / inputSize.x;

    float gradient = radius * 0.3;
    float radius = (radius - gradient * 0.5) / inputSize.x;

    float countLimit = MAX_KERNEL_SIZE;

    vec2 dir = vec2(center.xy / inputSize.xy - vTextureCoord);
    float dist = length(vec2(dir.x, dir.y * inputSize.y / inputSize.x));

    float strength = strength;

    float delta = 0.0;
    float gap;
    if (dist < innerRadius) {
        delta = innerRadius - dist;
        gap = minGradient;
    } else if (radius >= 0.0 && dist > radius) { // radius < 0 means it's infinity
        delta = dist - radius;
        gap = gradient;
    }

    if (delta > 0.0) {
        float normalCount = gap / inputSize.x;
        delta = (normalCount - delta) / normalCount;
        countLimit *= delta;
        strength *= delta;
        if (countLimit < 1.0)
        {
            gl_FragColor = texture2D(uSampler, vTextureCoord);
            return;
        }
    }

    // randomize the lookup values to hide the fixed number of samples
    float offset = rand(vTextureCoord, 0.0);

    float total = 0.0;
    vec4 color = vec4(0.0);

    dir *= strength;

    for (float t = 0.0; t < MAX_KERNEL_SIZE; t++) {
        float percent = (t + offset) / MAX_KERNEL_SIZE;
        float weight = 4.0 * (percent - percent * percent);
        vec2 p = vTextureCoord + dir * percent;
        vec4 sample = texture2D(uSampler, p);

        // switch to pre-multiplied alpha to correctly blur transparent images
        // sample.rgb *= sample.a;

        color += sample * weight;
        total += weight;

        if (t > countLimit){
            break;
        }
    }

    color /= total;
    // switch back from pre-multiplied alpha
    // color.rgb /= color.a + 0.00001;

    gl_FragColor = color;
}
`
    })

    Effect.create({
			name: "ascii",
			defaults: { pixelSize: 8 },
			frag: `
varying vec2 vTextureCoord;

uniform vec4 filterArea;
uniform float pixelSize;
uniform sampler2D uSampler;

vec2 mapCoord( vec2 coord )
{
    coord *= filterArea.xy;
    coord += filterArea.zw;

    return coord;
}

vec2 unmapCoord( vec2 coord )
{
    coord -= filterArea.zw;
    coord /= filterArea.xy;

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