Scene("PlayScene",{
    onStart: function(scene) {
		scene.player = new Ship()
		scene.player.x = Game.width / 2
		scene.player.y = Game.height / 2
		
		Game.background_color = Draw.black
    },
    onUpdate: function(scene, dt) {
        
    },
    onEnd: function(scene) {

    }
});
