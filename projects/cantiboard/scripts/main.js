let main_text;
let g;

Scene("main",{
	onStart (scene) {
		Game.background_color = Draw.white;
		main_text = new Text('1', {
			wordWrap: true,
			breakWords: false,
			onDraw: (i)=>{
				i.sprite.scale.set(Util.lerp(1,2,i.x/100))
				i.sprite.align = "left center";
				i.y += Util.sinusoidal(0,10,0.1,Util.lerp(0,10,i.x/100));
			}
		});
		main_text.y = 100;
		Timer.every(1000,(i)=>{
			if (i < 9)
				main_text.text = "123456789 ".repeat(i);
		});
	},
	onUpdate (scene, dt) {
		
	}
})

