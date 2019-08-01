class Board {
	constructor (size=32) {
		this.size = size;
		
		this.obj_canvas = new Canvas()
		this.obj_draw = new Draw(
			['lineStyle',1,Draw.black],
			['rect',1,1,this.size,this.size],
		);
		Util.aliasProps(this,this.obj_canvas,
			['x','y','scale']			
		)
		this.debug = new Draw();
	}
	setRect () {
		this.obj_canvas.rect = new Rectangle(
			0,0,this.width/this.scale.x, this.height/this.scale.y
		)
		this.debug.draw(
			['lineStyle',1,Draw.red],
			['rect',this.x,this.y,this.width,this.height]
		)
	}
	get (prop) {
		if (prop == 'scale') this.setRect();
	}
	set (prop, v) {
		if (prop == 'x' || prop == 'y') this.setRect();
	}
	click (fn) {
		Input.on('click',this.obj_canvas,fn);	
	}
	draw (...args) {
		this.obj_draw.draw(
			['lineStyle',1,Draw.black],
			['rect',1,1,this.size,this.size],
			...args
		);
		this.instructions = args;
		this.obj_draw.alpha = 1;
		this.obj_canvas.draw(this.obj_draw)
		this.obj_draw.alpha = 0;
		//this.setRect();
	}
	get width () { return this.obj_draw.width * this.obj_canvas.scale.x }
	get height () { return this.obj_draw.height * this.obj_canvas.scale.y }
}
Board.saves = {};

TestScene({
	onStart () {
		let board = new Board(32);	
		board.scale.set(4);
		board.y = 100;
		board.draw(
			['lineStyle',1,Draw.blue],
			['circle',16,16,8]
		)
		board.click(()=>{
			console.log("hi 1")
		})
		let board2 = new Board();
		board2.draw(
			['lineStyle',1,Draw.red],
			['circle',16,16,8]
		)
		board2.click(()=>{
			console.log("hi 2")
		})
		board2.scale.set(1);
		board2.x = board.x + board.width;
		board2.y = board.y + board.height - board2.height;
	}
})