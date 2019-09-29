Input.set("move_l","left","a")
Input.set("move_r","right","d")
Input.set("move_u","up","w")
Input.set("move_d","down","s")
Input.set("shoot","space")

class Ship extends Entity {
    init () {
		this.addSprite("ship")
		this.sprite_align = "center"
		this.friction = 0.001
		this.total_spd = 0;
		this.can_shoot = true;
    }
    update (dt) {
		// turning
		let move_spd = 1.8;
		if (Input("move_l").pressed)
			this.sprite_angle -= move_spd
		if (Input("move_r").pressed)
			this.sprite_angle += move_spd
		
		// accelerating
		let accel = 0.05
		if (Input("move_u").pressed && this.speed < 2)
			this.moveDirection(this.sprite_angle-90, accel, true)
		// deccelerating
		if (Input("move_d").pressed && this.speed > 0)
			this.moveDirection(this.direction, -accel, true)
			
		// wrapping
		if (this.y < 0) this.y = Game.height
		if (this.x < 0) this.x = Game.width
		if (this.y > Game.height) this.y = 0
		if (this.x > Game.width) this.x = 0
		
		// shooting
		if (Input("shoot").released && this.can_shoot) {
			let new_bullet = new Bullet(this);			
			this.can_shoot = false;
			Timer.after(200,()=>{ this.can_shoot = true });
		}	
    }
}
