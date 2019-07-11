let bob;
let drawing;
let my_view;
Scene("ScenePlay",{
    onStart: function(scene) {
		bob = new Robot();
		bob.x = 50
		bob.y = 50
		Game.background_color = Draw.black;
	},
    onUpdate: function() {
    },
    onEnd: function() {
		
    }
});