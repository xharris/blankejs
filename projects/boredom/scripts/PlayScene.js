Scene("PlayScene",{
    onStart: function(sc) {
		Game.background_color = Draw.white;
		Map.config = {
			z_index: {
				'ground':-5
			},
			tile_hitbox: {
				'ground': ['ground'],
				'death': ['spike']
			},
			entities: [Player,MovingBlock],
			hitboxes: ["ground"]
		};
		let map = Map.load("level1")
		//map.debug = true;
		sc.player = map.entities['Player'][0]
		sc.player.z = 20;
		View(sc.player)
    },
    onUpdate: function(scene, dt) {
        
    },
    onEnd: function(scene) {

    }
});
