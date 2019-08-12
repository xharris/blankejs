class Ball extends Entity {
    init () {
		// look like a bouncy ball
		this.addSprite("ball");//, {image:"ball", frames:1, speed:1, frame_size:[15,15]})
		this.sprite_align = "center"
		// fall towards the bottom of the screen
		this.gravity = 0.1;
		this.gravity_direction = 90
		
		this.addShape("main","circle")
		
		this.onCollision['main'] = (other, res) => {
			this.collisionBounce(Util.lerp(1,1.01,this.y/Game.height))
			Event.emit("ball_bounce")
		}
		
    }
    update (dt) {
		if (this.x < 0 || this.x > Game.width)
			this.hspeed = -this.hspeed;
    }
}

TestScene({
	onStart (sc) {
		let bob = new Ball();
		bob.x = 100;
		
		sc.box = new Hitbox({
			type: 'rect',
			shape: [0,Game.height/2,100,10],
			tag: 'Paddle',
			debug: true
		})
	},
	onUpdate (sc) {
		sc.box.position(Input.mouse.global.x, Input.mouse.global.y)
	}
})