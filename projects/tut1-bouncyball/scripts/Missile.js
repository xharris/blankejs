class Missile extends Entity {
    init () {
		this.addSprite("missile")
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
		let pad = new Paddle()
		pad.x = 150
		pad.y = 150
		let m = new Missile()
		m.x = 50
		m.y = 300
	}
})