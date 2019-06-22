let { Text } = game_instance;

let txt;

Scene("Play",{
    onStart: function() {
		let map_test1 = Map.load("test1")
		map_test1.spawnEntity(Player,"player",{align:"bottom"})
	
		txt = new Text("hey there",{
			fontSize: 36,
			fontStyle: 'italic',
			fontWeight: 'bold',
			fill: ['#ffffff', '#00ff99'], // gradient
			stroke: '#4a1850',
			strokeThickness: 5,
			dropShadow: true,
			dropShadowColor: '#000000',
			dropShadowBlur: 4,
			dropShadowAngle: Math.PI / 6,
			dropShadowDistance: 6,
		});
		txt.x = 100;
		txt.y = 100;
	},
    onUpdate: function(scene, dt) {
        txt.text = dt;
    },
    onEnd: function() {

    }
});
