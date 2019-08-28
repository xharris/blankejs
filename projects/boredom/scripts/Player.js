Input.set("left","a","left")
Input.set("right","d","right")
Input.set("up","w","up")
Input.set("action","space","j")

class Player extends Entity {
    init () {
		this.addSprite("player_stand", {image:"player_stand", frames:1, speed:1, frame_size:[21,32]})
    	this.sprite_align = "center"
		this.addShape("main","rect")
		
		this.walk_spd = 2;
	}
    update (dt) {
		// left / right movement
		this.hspeed = 0;
		if (Input("left").pressed)
			this.hspeed -= this.walk_spd;
		if (Input("right").pressed)
			this.hspeed += this.walk_spd;
    }
}

TestScene({
	onStart () {
		Map.config.tile_hitbox = {
			'ground': ['ground']	
		}
		let map = Map.load("level1")
		map.spawnEntity(Player)
	}
})