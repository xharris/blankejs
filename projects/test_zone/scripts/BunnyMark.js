Scene("BunnyMark",{
    onStart: function(scene) {
		scene.txt_count = new Text('0', {
			fontSize: 150,
			fill: Draw.white,
			stroke: Draw.black,
			strokeThickness: 4
		})
		scene.txt_count.x = 100;
		scene.txt_count.y = 100;
		scene.txt_count.z = 1000;
		new Bunny()
		
		Timer.every(100,function(){
			new Bunny();
			scene.txt_count.text = Bunny.instances.length;
		});
    },
    onUpdate: function(scene, dt) {
		
    },
    onEnd: function(scene) {

    }
});
