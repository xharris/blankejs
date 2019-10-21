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
		
		scene.effect = "shadertoy"
    },
    onUpdate: function(scene, dt) {
		scene.effect.shadertoy.center = [Game.width/2, Game.height/2]
			//[Input.mouse.global.x, Input.mouse.global.y];
    },
    onEnd: function(scene) {

    }
});
