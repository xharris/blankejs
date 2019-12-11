let txt, player, map_test1;

Scene("Play",{
    onStart: function(scene) {
		map_test1 = Map.load("test1")
		player = map_test1.spawnEntity(Player,"player",{
			align:"bottom",
			keep:false
		})[0];
		map_test1.effect = "wub";
	},
    onUpdate: function(scene, dt) {
		map_test1.effect.wub.val = Util.sinusoidal(0,1,0.05);
	},
    onEnd: function() {
		
    }
});

Effect.create({
	name: "wub",
	defaults: {val:0},
	frag: `
varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform float val;

void main(void)
{
	gl_FragColor = texture2D(uSampler, vTextureCoord);
	gl_FragColor.r = val;
}
`
})
