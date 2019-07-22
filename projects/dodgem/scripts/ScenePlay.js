let bob;
let drawing;
let my_view;

Scene("ScenePlay",{
    onStart: function(scene) {
		bob = new Robot();
		bob.x = Game.width / 2
		bob.y = Game.height / 2
		
	},
    onUpdate: function(scene, dt) {
		// draw trail
		//drawing.draw(bob)
    },
    onEnd: function() {
		
    }
});