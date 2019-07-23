
class Ball extends Entity {
    init (x,y,b_type) {
		this.addSprite("ball", {image:"balls", frames:5, speed:0, frame_size:[128,128]})
    	this.x = x;
		this.y = y;
		this.sprite_frame = b_type-1
		//thi
	}
    update (dt) {

    }
}

TestScene({
	onStart: () => {
		for (let size of [1,2,3,4,5]) {		
			new Ball(50,((size-1)*128));
		}
	}
})