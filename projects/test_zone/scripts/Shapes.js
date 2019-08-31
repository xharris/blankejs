class Circle extends Entity {
    init (align) {
		this.addSprite("main","circle")
		if (align) this.sprite_align = align;
		this.addShape("main","circle")
		this.debug = true;
    }
    update (dt) {

    }
}

class Rect extends Entity {
	init (align) {
		this.addSprite("main","rect")
		if (align) this.sprite_align = align;
		this.addShape("main","rect")
		this.debug = true;
	}
}