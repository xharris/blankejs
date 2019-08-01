class Board extends Entity {
	init () {
		this.canvas = new Canvas()
		this.draw = new Draw(
			['lineStyle',1,Draw.black],
			['rect',1,1,64,64],
			['circle',32,32,16]
		);
		this.canvas.draw(this.draw)
		this.draw.alpha = 0;
		this.canvas.scale.set(8)
	}
}

TestScene({
	onStart () {
		new Board();	
	}
})