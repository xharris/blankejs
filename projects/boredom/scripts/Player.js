Input.set("left","a","left")
Input.set("right","d","right")
Input.set("up","w","up")
Input.set("down","s","down")
Input.set("action","space","j")

class Player extends Entity {
    init () {
		this.addSprite("stand", {image:"player_stand", frames:1, speed:1, frame_size:[21,32]})
    	this.addSprite("walk", {image:"player_walk", frames:2, speed:0.15, frame_size:[21,32]})
		this.addSprite("dead", "player_dead")
		this.sprite_align = "center"
		this.sprite_index = "walk"
		
		this.can_jump = true;
		this.jump_height = 6;
		this.walk_spd = 2.25;
		this.gravity_direction = 90;
		this.gravity = 0.15;
		
		this.addPlatforming({
			tag: 'ground',
			width: this.sprite_width-8,
			height: this.sprite_height,
			on:{
				any: (other) => {
					if (other.tag == 'death')
						this.die(other.tag);
				},
				foot: () => { 
					this.grounded = true;
					this.can_jump = true
				}	
			}
		})
	}
	die (tag) {
		if (!this.dead) {
			this.dead = true;
			this.sprite_index = "dead";
			this.friction = 0.01;
		}
	}
    update (dt) {
		if (this.dead) return;
		
		// left / right / jump movement
		this.hspeed = 0;
		if (Input("left").pressed)
			this.hspeed -= this.walk_spd;
		if (Input("right").pressed)
			this.hspeed += this.walk_spd;
		if (Input("up").pressed && this.can_jump) {
			this.can_jump = false;
			this.vspeed = -this.jump_height;
		}
		// animation index
		if (!this.grounded) {
			this.sprite_index = 'walk';
			this.sprite_frame = 1;
		} else if ((Input("left").pressed || Input("right").pressed) && this.grounded) {
			this.sprite_index = 'walk';
			this.sprite_speed = 0.15;
		} else {
			this.sprite_index = 'stand';
		}
		
		this.grounded = false;
		// animation direction
		if (Input("left").pressed) this.sprite_scale.x = -1;
		else if (Input("right").pressed) this.sprite_scale.x = 1;
	}
}