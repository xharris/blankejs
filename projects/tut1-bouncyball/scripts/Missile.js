class Missile extends Entity {
    init () {
		this.addSprite("ball")
		this.sprite_align = "center"
		this.homing = true;
		Timer.after(10, ()=>{
			this.homing = false;
		})
    }
    update (dt) {
		this.sprite_angle = this.direction;
		let paddle = Paddle.instances[0];
		if (this.homing) {
			this.moveTowards(paddle.x, paddle.y, 1)
		}
    }
}

TestScene({
	onStart () {
		new Paddle()
		let m = new Missile()
		m.x = 50
		m.y = 300
	}
})