class Paddle extends Entity {
    init () {
		this.addSprite("paddle")
		this.sprite_align = "center"
		//this.sprite_scale.set(0.5)
		
		this.friction = 0.4;
		this.addShape("main","rect")
		// explode on contact with a missile
		this.onCollision['main'] = (other) => {
			if (other.tag == "Ball")
				this.explode()
		}
    }
    update (dt) {
		// Move the player presses keys
		let move_spd = 5;
		if (Input("move_left").pressed)
			this.hspeed = -move_spd;
		if (Input("move_right").pressed)
			this.hspeed = move_spd;
		if (Input("move_up").pressed)
			this.vspeed = -move_spd;
		if (Input("move_down").pressed)
			this.vspeed = move_spd;
		// 'teleport' it to the other side of the screen, if it goes out of bounds
		if (this.x > Game.width)
			this.x = 0;
		if (this.x < 0)
			this.x = Game.width;
    }
	explode () {
		if (this.exploded) return;
		this.exploded = true;
		
		let paddle_bits = this.sprites['paddle'].chop(5,8)
		this.visible = false;
		paddle_bits.forEach(b => {
			let direction = Util.rand_range(45,135)
			b.hspeed = Util.direction_x(direction, 10)
			b.vspeed = Util.direction_y(direction, 10)
		})
		this.destroy();
	}
}

Scene("bob",{
	onStart (s) {
		let pad = new Paddle();
		pad.y = Game.height/2;
		pad.x = pad.sprite_width/2;
		let ball = new Ball();
		ball.x = 40
	}
})