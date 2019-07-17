let bob;
let drawing;
let my_view;

Scene("ScenePlay",{
    onStart: function(scene) {
		bob = new Robot();
		bob.x = 50
		bob.y = Game.height - bob.sprite_height
		
		drawing = new Draw(
			['fill',Draw.blue],
			['rect',0,0,100,100]
		)
		drawing.z = -1;
		
		new Draw(
			['lineStyle',1,Draw.black],
			['rect',1,1,Game.width-2,Game.height-2],
			['rect',20,20,100,Game.height]
		)
		
		let bop = View("player")
		bop.port_width = 100;
		bop.port_height = 100;
		bop.follow(bob);
		bop.angle = 45;
	},
    onUpdate: function(scene, dt) {
		drawing.x = Util.sinusoidal(0,100,0.02)
    },
    onEnd: function() {
		
    }
});