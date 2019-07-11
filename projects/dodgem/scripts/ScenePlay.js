let bob;
let drawing;
let my_view;
Scene("ScenePlay",{
    onStart: function(scene) {
		bob = new Robot();
		bob.x = 50
		bob.y = 50
		
		my_view = View("bob")
		
	},
    onUpdate: function() {
    },
    onEnd: function() {
		
    }
});