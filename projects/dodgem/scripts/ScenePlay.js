let bob;
let drawing;
let my_view;

Scene("ScenePlay",{
    onStart: function(scene) {
		bob = new Robot();
		bob.x = 0
		bob.y = 0
		jon = new Sprite({image:"blue_robot", frames:6, speed:0.7, frame_size:[38,33], offset:[38,0]})
		jon.x = 20
		jon.y = Game.height - bob.sprite_height
		Input.on('click',jon,()=>{
			console.log('ok then')
		})	
		
		drawing = new Draw(
			['lineStyle',5,Draw.blue,1,0],
			['rect',0,0,300,300],
			['fill']
		)
		//drawing.auto_clear = false;
		//drawing.z = -1;
		let cam = View("bob",bob)
		cam.add(scene)
		//cam.port_width = 300
		//cam.port_height = 300
		/*
		let cam2 = View("bob2",bob)
		cam2.add(scene)
		*/
	},
    onUpdate: function(scene, dt) {
		// draw trail
		//drawing.draw(bob)
    },
    onEnd: function() {
		
    }
});