Scene("Effect",{
    onStart: function(scene) {
		scene.player = new Player('center')
		scene.player.x = Game.width / 4;
		scene.player.y = 200;
		
		Game.background_color = Draw.white2
		scene.graphic = new Draw(
			['fill',Draw.green],
			['lineStyle',3,Draw.black2],
			['star',100,Game.height/2,5,50]
		)
		scene.graphic.effect = "ascii"
    },
    onUpdate: function(scene, dt) {
		//scene.graphic.effect.zoomblur.center = [Input.mouse.global.x, Input.mouse.global.y];
    },
    onEnd: function(scene) {

    }
});
