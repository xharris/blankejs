let bob;
let drawing;
Scene("ScenePlay",{
    onStart: function() {
		bob = new Robot();
		bob.x = 50
		bob.y = 50
		bob.visible = false
		
		drawing = new Draw(
			['fill', Draw.green],
			//['rect', 100, 100, 200, 200],
			//['hole'],
			['moveTo', 100, 100],
			['arc', 100, 100, 150, 0, 90]
			//['hole']
		)
    },
    onUpdate: function() {
        bob.x = Util.sinusoidal(50,100,0.1)
    },
    onEnd: function() {
		
    }
});
