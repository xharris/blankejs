class Missile extends Entity {
    init () {
		this.addSprite("missile")
		this.sprite_align = "center"
		// after 10 seconds, stop homing in on the Paddle
		this.homing = false;
		Timer.after(10, ()=>{
			this.homing = false;
		})
		// wait 3 seconds before moving
		this.sprite_alpha = 0
		let twn = new TWEEN.Tween(this)
			.to({ sprite_alpha:1 },3000)
			.easing(TWEEN.Easing.Quadratic.Out)
			.onComplete(()=>{
				this.homing = true;
				this.addShape('main','circle')
			})
			.start()
		
    }
    update (dt) {
		this.sprite_angle = this.direction + 90;
		let paddle = Paddle.instances[0];
		
		if (!paddle) {
			this.homing = false
		}
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
		m.x = 100
		m.y = 200
	}
})