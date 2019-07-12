let bob;
let drawing;
let my_view;
Scene("ScenePlay",{
    onStart: function(scene) {
		bob = new Robot();
		bob.x = 50
		bob.y = 50
		
		my_view = View("bob")
		drawing = new Draw(
			['fill',Draw.blue],
			['rect',0,0,100,100]
		)
		drawing.z = -1;
	},
    onUpdate: function() {
		drawing.x = Util.sinusoidal(0,100,0.02)
    },
    onEnd: function() {
		
    }
});