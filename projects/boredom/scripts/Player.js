Input.set("left","a","left")
Input.set("right","d","right")
Input.set("up","w","up")
Input.set("action","space","j")

class Player extends Entity {
    init () {
		this.addSprite("player_stand", {image:"player_stand", frames:1, speed:1, frame_size:[21,32]})
    	this.sprite_align = "center"
		this.addShape("main","rect")
		
		this.can_jump = true;
		this.walk_spd = 3;
		this.gravity_direction = 90;
		this.gravity = 0.5;
		
		this.onCollision['main'] = (other, info) => {
			if (info.sep_vec.y > 0) {
				this.collisionStopY();
				this.can_jump = true;
			}
			if (info.sep_vec.x != 0) {
				this.collisionStopX();
			}
		}
	}
    update (dt) {
		// left / right movement
		this.hspeed = 0;
		if (Input("left").pressed)
			this.hspeed -= this.walk_spd;
		if (Input("right").pressed)
			this.hspeed += this.walk_spd;
		if (Input("up").pressed && this.can_jump) {
			this.can_jump = false;
			this.vspeed = -10;
		}
    }
}