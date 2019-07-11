
class Robot extends Entity {
    init () {
		this.addSprite("run", {image:"blue_robot", frames:6, speed:0.7, frame_size:[38,33], offset:[38,0]})
    }
    update (dt) {
 
    }
}

TestScene({
	onStart: (s) => {
		s.rob = new Robot();
		s.rob.x = 50;
		s.rob.y = 50;
		Game.background_color = Draw.blue;
		
		let drawing = new Draw(
			['fill', Draw.green],
			['rect', 100, 100, 200, 200],
			['hole'],
			['moveTo', 100, 100],
			['arc', 100, 100, 150, 0, 90],
			['hole'] 
		)
		
		//TestView("player",s.rob);
	},
	onUpdate: (s, dt) => {
		s.rob.x = Util.sinusoidal(50,100,0.1)
	}
})
