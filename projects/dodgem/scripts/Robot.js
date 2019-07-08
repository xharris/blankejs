
class Robot extends Entity {
    init () {
		this.addSprite("run", {image:"blue_robot", frames:6, speed:0.4, frame_size:[38,33], offset:[38,0]})
    }
    update (dt) {

    }
}

TestScene({
	onStart: () => {
		let rob = new Robot();
		rob.x = 50;
		rob.y = 50;
	}
})
