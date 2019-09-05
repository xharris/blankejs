Scene("BunnyMark",{
	particle_z:0,
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
		
		//Timer.every(1000,function(){
			Util.repeat(10000 /*20000*/,()=>{
				let b = new Bunny();
				b.particle = true;
			});
			scene.txt_count.text = Bunny.instances.length;
		//});
    },
    onUpdate: function(scene, dt) {
		
    },
    onEnd: function(scene) {

    }
});
