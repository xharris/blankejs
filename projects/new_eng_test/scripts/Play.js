Scene("Play",{
    onStart: function() {
		let map_test1 = Map.load("test1")
    	map_test1.spawnEntity(Player,"player",{align:"bottom"})
	},
    onUpdate: function() {
        
    },
    onEnd: function() {

    }
});
