
Input.set("left","a","left")
Input.set("right","d","right")
Input.set("up","w","up")
Input.set("down","s","down")

class Robot extends Entity {
    init () {
		this.addSprite("run", {image:"blue_robot", frames:6, speed:0.1, frame_size:[38,33], offset:[38,0]})
    }
    update (dt) {
		this.hspeed = 0;
		this.vspeed = 0;
 		if (Input("left").pressed)
			this.hspeed = -2;
 		if (Input("right").pressed)
			this.hspeed = 2;
		if (Input("up").pressed)
			this.vspeed = -2;
		if (Input("down").pressed)
			this.vspeed = 2;
    }
}

TestScene({
	onStart: (s) => {
		s.rob = new Robot();
		new Draw(
			['lineStyle',1,Draw.black],
			['rect',1,1,Game.width-2,Game.height-2]	
		)
		TestView("player",s.rob);
	},
	onUpdate: (s,dt) => {
		let view = TestView("player")
		//console.log(view.port_width, view.port_height);
	}
})
