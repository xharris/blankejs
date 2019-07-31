let main_text;

Scene("main",{
	onStart (scene) {
		Game.background_color = Draw.white;
		let str = "jimbo";
		main_text = new Text(str, {
			wordWrap: true,
			
			onDraw: (i)=>{
				i.y += Util.sinusoidal(0,10,0.1,Util.lerp(0,10,i.x/100));
			}
		});
		main_text.y = 100;
		Timer.every(1000,(i)=>{
			if (i < 20)
				main_text.text = "123456 789".repeat(i*2);
		});
	},
	onUpdate (scene, dt) {
	}
})

