class MovingBlock extends Entity {
    init () {
		this.addSprite("moving_block")
		this.sprite_align = "center"
		
		this.addShape("main","rect","ground")
		this.debug=true
    }
    update (dt) {

    }
}
