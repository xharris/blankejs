class Player extends Entity {
	init () {
		this.addSprite('player_stand');
		this.z = 20;
	}
	update (dt) {
		this.hspeed = 0;
		this.vspeed = 0;
		if (Input("move_right").pressed)    this.hspeed = 5;
		if (Input("move_left").pressed)     this.hspeed = -5;
		if (Input("move_up").pressed)       this.vspeed = -5;
		if (Input("move_down").pressed)     this.vspeed = 5;
	}
}

TestScene({
	onStart: () => {
		Map.load("test1")
		let player = new Player();
	}
})