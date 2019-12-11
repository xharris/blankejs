Scene("BunnyMark",{
	particle_z:0,
    onStart: function(scene) {
		scene.txt_count = new Text('0', {
			fontSize: 75,
			fill: Draw.white,
			stroke: Draw.black,
			strokeThickness: 4
		})
		scene.txt_count.x = 100;
		scene.txt_count.y = 100;
		scene.txt_count.z = 1000;
		
		Input.set("action","space");
    },
    onUpdate: function(scene, dt) {
		if (Input("action").released) {
			Util.repeat(5000,()=>{
				let b = new Bunny();
				b.particle = true;
			});
			scene.txt_count.text = Bunny.instances.length;
		}
    },
    onEnd: function(scene) {

    }
});
