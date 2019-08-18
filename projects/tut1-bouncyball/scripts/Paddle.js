class Paddle extends Entity {
    init () {
		this.addSprite("paddle")
		this.sprite_align = "center"
		this.sprite_scale.set(0.5);
		this.friction = 0.4;
		this.addShape("main","rect")
		// explode on contact with a missile
		this.onCollision['main'] = (other) => {
			if (other.tag == "Missile") {
				other.parent.destroy()
				this.explode()
			}
			if (other.tag == "Ball")
				console.log("oh wow")
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
		if (this.y < 0)
			this.y = Game.height;
		if (this.y > Game.height)
			this.y = 0;
    }
	explode () {
		if (this.exploded) return;
		this.exploded = true;
		
		Event.emit('paddle_explode')
		
		let paddle_bits = this.sprites['paddle'].chop(5,8)
		paddle_bits.forEach(b => {
			let direction = Util.rand_range(0,360)
			b.hspeed = Util.direction_x(direction, 10)
			b.vspeed = Util.direction_y(direction, 10)
		})
		this.destroy();
	}
}

TestScene({
	onStart (s) {
		Input.set('explosion','space')
		new Ball();
		s.pad = new Paddle();
		s.pad.y = Game.height/2;
		s.pad.x = s.pad.sprite_width/2;
		let ball = new Ball();
		ball.x = 40
	}, 
	onUpdate (s, dt) {
		if (Input('explosion').released) {
			s.pad.explode()
		}
	}
})