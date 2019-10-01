Scene("Particles",{
    onStart: function(scene) {
		scene.player = new Player('center')
		scene.player.x = Game.width / 4;
		scene.player.y = 200;
		
		let part = new Particles()
		part.rate = 55;
		part.graphic = scene.player;
		
		//View(scene.player)
    },
    onUpdate: function(scene, dt) {
		
    },
    onEnd: function(scene) {

    }
});
