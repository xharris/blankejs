class Ball extends Entity {
    init () {
		// look like a bouncy ball
		this.addSprite("ball")
		this.sprite_align = "center"
		// fall towards the bottom of the screen
		this.gravity = 0.1;
		this.gravity_direction = 90
		
		this.addShape("main","circle")
		
		this.onCollision['main'] = () => {
			this.vspeed = -Math.abs(this.vspeed*1.03);
			//this.collisionStopY();
		}
    }
    update (dt) {

    }
}

TestScene({
	onStart () {
		let bob = new Ball();
		bob.x = 20;
		bob.y = 20;
		
		new Hitbox({
			type: 'rect',
			shape: [0,Game.height/2,200,10],
			debug: true
		})
	}
})