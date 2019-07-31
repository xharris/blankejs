let main_text;

Scene("main",{
	onStart (scene) {
		let str = "abcdaaaabbbbccccddddabcd5";"jimbo";
		main_text = new Text(str, {
			onDraw: (info)=>{
				//info.sprite.scale.set(0,2);
				info.y = Util.sinusoidal(0,10,0.1,
							Util.lerp(0,10,(info.i+1)/info.string.length)
						);
			}
		});
		main_text.y = 100;
		//main_text.text = "abcd aaaa bbbb cccc dddd abcd"
		//Timer.every(1000,(i)=>{
			//main_text.text = 'jimbo';
		//});
	},
	onUpdate (scene, dt) {
	}
})

