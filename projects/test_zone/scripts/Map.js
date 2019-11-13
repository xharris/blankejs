Scene("Map",{
    onStart: function(scene) {
		Map.config.layer_order = ['front','back']
		Map.config.entities = [Player,Bunny]
		Map.load('map0')
    },
    onUpdate: function(scene, dt) {
        
    },
    onEnd: function(scene) {

    }
});
