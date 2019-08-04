// [1] soccer : bounces, affected by gravity downwards
// [2] beach ball : move diagonal, bounce top/bottom
// [3] spikey : move straight right, accelerates
// [4] bowling ball : like beach ball, slower
// [5] smiley : bounces, affected by gravity up/downwards

/* sounds
beach -> car door
bowling -> cannon
spike -> crunchy
smile -> drip
soccer -> switch1
*/

class Ball extends Entity {
    init () {
		this.addSprite("ball", {image:"balls", frames:5, speed:0, frame_size:[128,128]})
		this.sprite_pivot.set(this.sprite_width/2, this.sprite_height/2)
		
		let b_type = Util.rand_range(0,6);
		this.b_type = b_type;
		let scale;
		if (b_type == 4) // bowling ball
			scale = 2;
		else if (b_type == 4 || b_type == 2) // bowling ball, beach ball
			scale = 1;
		else 
			scale = 0.5;
		
		this.sprite_scale.set(scale);
		this.addShape('main',{type:'circle',shape:[0,0,this.sprite_width/2 - (15*scale)]})
		
		this.x = -this.sprite_width;
		this.y = Util.rand_range(0,Game.height/2);
		this.sprite_frame = b_type-1;
		this.debug = true;
		
		switch (b_type) {
			case 1: // soccer
				this.hspeed = 3;
				this.gravity_direction = 90;
				this.gravity = 0.2;
				break;
			case 2: // beach ball
				this.moveDirection(Util.rand_choose([-45,45]),10)
				break;
			case 3: // spikey
				this.hspeed = 0;
				break;
			case 4: // bowling ball
				this.moveDirection(Util.rand_choose([-45,45]),2)
				break;
			case 5: // smiley
				this.hspeed = 3;
				this.gravity_direction = 90 * -Util.rand_choose([-1,1]);
				this.gravity = 0.2;
				break;
		}
	}
    update (dt) {
		if (this.y < this.sprite_height/2) {
			this.y = this.sprite_height/2
			this.vspeed = -this.vspeed;
		}
		if (this.y > Game.height - this.sprite_height/2) {
			this.y = Game.height - this.sprite_height/2
			this.vspeed = -this.vspeed;
		}
		// beach ball
		if (this.b_type == 3)
			this.hspeed += 0.2;
		
		if (this.x > Game.width + this.sprite_width/2)
			this.destroy();
    }
}

TestScene({
	onStart: () => {
		Timer.every(1000,()=>{
			new Ball();
		});
	}
})