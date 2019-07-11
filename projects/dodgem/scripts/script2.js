
TestScene({
	onStart: (s) => {
		s.rob = new Robot();
		s.rob.x = 50;
		s.rob.y = 50;
		
		let drawing = new Draw(
			['fill', Draw.green],
			['rect', 100, 100, 200, 200],
			['hole'],
			['moveTo', 100, 100],
			['arc', 100, 100, 150, 0, 90],
			['hole']
		)
		
		TestView("player",s.rob);
		Game.background_color = Draw.black;
	},
	onUpdate: (s, dt) => {
		s.rob.x = Util.sinusoidal(50,100,0.1)
	}
})