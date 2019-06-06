
Scene("Play",{
    onStart: function() {
		for (let p=0; p<1000; p++) {
			let bob = new Player;
			bob.x = Util.rand_range(10, Game.width - 10);
			bob.y = Util.rand_range(10, Game.height - 10);
			
			console.log(bob.x, bob.y)
		}	
    },
    onUpdate: function() {
        
    },
    onEnd: function() {

    }
});
