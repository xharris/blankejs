let bob;
let drawing;
Scene("ScenePlay",{
    onStart: function() {
		bob = new Robot();
		bob.x = 50
		bob.y = 50
		
		drawing = new Draw(
			['fill', Draw.green],
			['rect', 100, 100, 200, 200],
			['hole'],
			['moveTo', 100, 100],
			['arc', 100, 100, 150, 0, 90],
			['hole']
		)
		Input.on('click',[drawing,bob],()=>{ console.log('hi') });
    },
    onUpdate: function() {
        bob.x = Util.sinusoidal(50,100,0.1)
    },
    onEnd: function() {
		
    }
});
