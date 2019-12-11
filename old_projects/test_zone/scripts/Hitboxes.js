Scene("Hitboxes",{
    onStart: function(scene) {
		let c = new Circle("center");
		c.x = Game.width / 4;
		c.y = 100;
		console.log(c._getHitboxOffset('x'), c._getHitboxOffset('y'))
		
		let r = new Rect("center");
		r.x = Game.width / 4;
		r.y = 200;
		console.log(r._getHitboxOffset('x'), r._getHitboxOffset('y'))
    
		let p = new Player("center");
		p.x = Game.width / 4;
		p.y = 280;
		
		new Draw(
			['lineStyle',2,Draw.black],
			['moveTo',Game.width/4,0],
			['lineTo',Game.width/4,Game.height]
		);
		
		scene.c = c;
		scene.r = r;
	},
    onUpdate: function(scene, dt) {
        scene.c.sprite_angle += 0.25;
        scene.r.sprite_angle += 0.25;
    },
    onEnd: function(scene) {

    }
});
