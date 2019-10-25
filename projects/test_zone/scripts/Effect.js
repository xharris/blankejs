Scene("Effect",{
    onStart: function(scene) {
		scene.player = new Player('center')
		scene.player.x = Game.width / 4;
		scene.player.y = 200;
		
		scene.graphic = new Draw(
			['fill',Draw.green],
			['lineStyle',3,Draw.black2],
			['star',100,Game.height/2,5,50]
		)
		Effect.create({
			name: "shadertoy",
			defaults: { uCenter: [0, 0], uStrength: 0.1, uInnerRadius: -1, uRadius: -1 },
			frag:`
precision highp float;
varying vec2 vTextureCoord;

uniform sampler2D uSampler;
uniform vec2 iMouse;
uniform vec4 inputSize;
uniform vec4 outputFrame;
uniform float time;

void main() {
	float focusPower = 10.0;

    vec2 fragCoord = vTextureCoord;

    vec2 uv = fragCoord.xy;
    vec2 mousePos = (iMouse.xy - outputFrame.xy) / inputSize.xy; // same as * inputSize.zw
	vec2 focus = uv - mousePos;
    
    vec4 outColor;
    outColor = vec4(0, 0, 0, 1);


    for (int i=0; i<${focusDetail}; i++) {
        float power = 1.0 - focusPower * (1.0/inputSize.x) * float(i);
        outColor.rgb += texture2D(uSampler, focus * power + mousePos).rgb;
    }
    
    outColor.rgb *= 1.0 / float(${focusDetail});

	gl_FragColor = outColor;
}
`})
		
		//scene.effect = "shadertoy"
    },
    onUpdate: function(scene, dt) {
		// scene.effect.shadertoy.center = [Game.width/2, Game.height/2]
			//[Input.mouse.global.x, Input.mouse.global.y];
    },
    onEnd: function(scene) {

    }
});
