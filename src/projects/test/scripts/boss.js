class Boss extends Entity {
    init () {
        this.addSprite({
            name: "stand",
            path: "assets/boss.png"
        });
        this.sprite_index = "stand";
    }
    
    update (dt) {
		this.x += 0.2;
    }
}