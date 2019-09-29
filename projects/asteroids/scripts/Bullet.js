class Bullet extends Entity {
    init (player) {
		this.img = new Draw()
		this.x = player.x
		this.y = player.y
		this.moveDirection(player.sprite_angle-90, 10)
		Timer.after(1500, ()=> { this.destroy() })
    }
    update (dt) {
		this.img.draw(
			['lineStyle',1,Draw.white],
			['fill',Draw.white],
			['rect',-1,-1,2,2]
		)
		this.img.x = this.x;
		this.img.y = this.y;
		
		// wrapping
		if (this.y < 0) this.y = Game.height
		if (this.x < 0) this.x = Game.width
		if (this.y > Game.height) this.y = 0
		if (this.x > Game.width) this.x = 0
    }
	onDestroy () {
		this.img.destroy() 
	}
}
