Input.set("left","a","left")
Input.set("right","d","right")
Input.set("up","w","up")
Input.set("down","s","down")
Input.set("action","space","j")

class Player extends Entity {
    init () {
		this.addSprite("player_stand", {image:"player_stand", frames:1, speed:1, frame_size:[21,32]})
    	this.sprite_align = "center"
		
		this.can_jump = true;
		this.jump_height = 6;
		this.walk_spd = 2.25;
		this.gravity_direction = 90;
		this.gravity = 0.2;
		
		this.addPlatforming({
			tag: 'ground',
			width: this.sprite_width-8,
			height: this.sprite_height,
			on:{
				foot: () => { this.can_jump = true }	
			}
		})
	}
    update (dt) {
		// left / right movement
		/*
		if (Input("down").pressed) this.y += 1.5;
		if (Input("up").pressed) this.y -= 1.5;
		if (Input("left").pressed) this.x -= 1.5;
		if (Input("right").pressed) this.x += 1.5;
		*/
		this.hspeed = 0;
		if (Input("left").pressed)
			this.hspeed -= this.walk_spd;
		if (Input("right").pressed)
			this.hspeed += this.walk_spd;
		if (Input("up").pressed && this.can_jump) {
			this.can_jump = false;
			this.vspeed = -this.jump_height;
		}
		// animation direction
		if (this.hspeed < 0) this.sprite_scale.x = -1;
		else if (this.hspeed > 0) this.sprite_scale.x = 1;
	}
}