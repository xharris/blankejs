Scene("PlayScene",{
    onStart: function(sc) {
		Map.config = {
			tile_hitbox: {
				'ground': ['ground']	
			},
			entities: [Player],
			hitboxes: ["ground"]
		};
		let map = Map.load("level1")
		//map.debug = true;
		sc.player = map.entities['Player'][0]
		View(sc.player)
    },
    onUpdate: function(scene, dt) {
        
    },
    onEnd: function(scene) {

    }
});
