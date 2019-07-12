
Input.set("left","a","left")
Input.set("right","d","right")

class Robot extends Entity {
    init () {
		this.addSprite("run", {image:"blue_robot", frames:6, speed:0.1, frame_size:[38,33], offset:[38,0]})
    }
    update (dt) {
		this.hspeed = 0;
 		if (Input("left").pressed)
			this.hspeed = -2;
 		if (Input("right").pressed)
			this.hspeed = 2;
    }
}

TestScene({
	onStart: (s) => {
		s.rob = new Robot();
		new Draw(
			['lineStyle',1,Draw.black],
			['rect',-50,-50,100,100]	
		)
		// TestView("player",s.rob);
		let view = View("player")
		view.follow(s.rob)
		view.add(s)
	}
})
