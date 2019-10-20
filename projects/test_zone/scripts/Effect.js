Scene("Effect",{
    onStart: function(scene) {
		scene.player = new Player('center')
		scene.player.x = Game.width / 4;
		scene.player.y = 200;
		
		scene.graphic = new Draw(
			['fill',Draw.green],
			['lineStyle',3,Draw.black2],
			['star',100,100,5,50]
		)
		
		scene.effect = "zoomblur"
    },
    onUpdate: function(scene, dt) {
		
    },
    onEnd: function(scene) {

    }
});
