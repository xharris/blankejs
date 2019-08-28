class Ball extends Entity {
    init () {
		// look like a bouncy ball
		this.addSprite("ball");//, {image:"ball", frames:1, speed:1, frame_size:[15,15]})
		this.sprite_align = "center"
		// fall towards the bottom of the screen
		this.gravity = 0.1;
		this.gravity_direction = 90;
		
		this.addShape("main","circle")
		
		this.onCollision['main'] = (other, res) => {
			if (other.tag == "Paddle") {
				this.collisionBounce(Util.lerp(1,1.03,this.y/Game.height))
				// this.hspeed += Math.max(
				let dist = this.x - (other.x+(other.parent.sprite_width/2));
				this.hspeed += dist/10;
				this.hspeed = Math.min(2,Math.abs(this.hspeed)) * Math.sign(this.hspeed);
				
				Event.emit("ball_bounce")
			}
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
		sc.pad = new Paddle();
	},
	onUpdate (sc) {
		sc.pad.x = Input.mouse.global.x;
		sc.pad.y = Input.mouse.global.y;
	}
})