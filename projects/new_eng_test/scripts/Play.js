//let { Text } = game_instance;

let txt;

Scene("Play",{
    onStart: function() {
		let map_test1 = Map.load("test1")
		let player = map_test1.spawnEntity(Player,"player",{align:"bottom"})[0];
		player.effect = "hi ther";
	},
    onUpdate: function(scene, dt) {
		
    },
    onEnd: function() {

    }
});
