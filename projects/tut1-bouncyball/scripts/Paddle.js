class Paddle extends Entity {
    init () {
		this.addSprite("paddle")
		this.sprite_align = "center"
		this.friction = 0.4;
		this.addShape("main","rect")
		this.debug = true
		this.x = 0
		this.y = 200
		for (let name in this.shapes) 
			console.log(name, this.shapes[name].type)
    }
    update (dt) {

    }
}

TestScene({
	onStart (s) {
		let pad = new Paddle();
		let ball = new Ball();
		ball.x = 40
		ball.debug = true
	}
})