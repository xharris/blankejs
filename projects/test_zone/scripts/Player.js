class Player extends Entity {
    init (align) {
		this.addSprite("main","player_stand")
		if (align) this.sprite_align = align;
		this.addShape("main","rect")
		this.sprite_scale.x = -1
		this.debug = true;
    }
    update (dt) {

    }
}
