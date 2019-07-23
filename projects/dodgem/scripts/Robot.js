
Input.set("left","a","left")
Input.set("right","d","right")
Input.set("up","w","up")
Input.set("down","s","down")

class Robot extends Entity {
    init () {
		this.addSprite("run", {image:"blue_robot", frames:6, speed:0.1, frame_size:[38,33], offset:[38,0]})
    	this.sprite_pivot.x = this.sprite_width / 2;
		this.move_speed = 4;
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
	onStart: (s) => {
		let rob = new Robot();
		TestView(rob);
		
	}
})
