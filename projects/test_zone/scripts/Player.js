class Player extends Entity {
    init (align) {
		this.addSprite("robot_walk", {image:"bluerobot", frames:6, speed:0.2, frame_size:[38,33], offset:[38,0]})
		if (align) this.sprite_align = align;
		this.addShape("main","rect")
		this.sprite_scale.x = 1
		
		Input.set("move_l","left","a")
		Input.set("move_r","right","d")
		Input.set("move_u","up","w")
		Input.set("move_d","down","s")
    }
    update (dt) {
		let spd = 2;
		this.hspeed = 0;
		this.vspeed = 0;
		if (Input("move_l").pressed) {
			this.hspeed -= spd;
			this.sprite_scale.x = -1;
		}
		if (Input("move_r").pressed) {
			this.hspeed += spd;
			this.sprite_scale.x = 1;
		}
		if (Input("move_u").pressed) this.vspeed -= spd;
		if (Input("move_d").pressed) this.vspeed += spd;
    }
}
