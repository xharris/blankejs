
class Robot extends Entity {
    init () {
		this.addSprite("run", {frames:6, frame_size:[38,33], speed:1, offset:[38,0], border:[0,0], image:"blue_robot"})
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
