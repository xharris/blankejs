
Input.set("left","a","left")
Input.set("right","d","right")
Input.set("up","w","up")
Input.set("down","s","down")

class Robot extends Entity {
    init () {
		this.addSprite("run", {image:"blue_robot", frames:6, speed:0.1, frame_size:[38,33], offset:[38,0]})
    	this.sprite_align = 'center';
		this.addShape('main','circle');
		this.move_speed = 3;
		this.debug = true;
		
		this.onCollide['main'] = (info, res) => {
			//console.log(info, res);
		}
	}
    update (dt) {
		// movement
		this.hspeed = 0;
		this.vspeed = 0;
 		if (Input("left").pressed)
			this.hspeed = -this.move_speed;
 		if (Input("right").pressed)
			this.hspeed = this.move_speed;
		if (Input("up").pressed)
			this.vspeed = -this.move_speed;
		if (Input("down").pressed)
			this.vspeed = this.move_speed;
		// animation
		if (Input('left','right').pressed.any)
			this.sprite_scale.x = Math.sign(this.hspeed);
    }
}

TestScene({
	onStart: (scene) => {
		let rob = new Robot();
		rob.x = 80;
		rob.y = 80;
		scene.test_ball = new Ball();
	},
	onUpdate: (scene, dt) => {
		scene.test_ball.x = 200;
		scene.test_ball.y = 200;
		scene.test_ball.hspeed = 0;
		scene.test_ball.vspeed = 0;
	}
})
