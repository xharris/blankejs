class Bunny extends Entity {
    init () {
		this.x = Game.width / 2;
		this.addSprite("rabbitv3")
		this.sprite_align = "center"
		this.gravity_direction = 90
		this.gravity = Util.rand_range(100,200)/1000;
		this.hspeed = Util.rand_choose([-1,1]) * Util.rand_range(0,1000)/100;
    }
    update (dt) {
		if (this.y > Game.height)
			this.vspeed = -this.vspeed;
		if (this.x > Game.width) {
			this.hspeed = -this.hspeed;
			this.x = Game.width - 1;
		}
		if (this.x < 0) {
			this.hspeed = -this.hspeed;
			this.x = 1;
		}
    }
}
