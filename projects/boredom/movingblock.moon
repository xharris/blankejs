import Entity, Hitbox from require "blanke"
import Tween from require "xhh-tween"

Entity "MovingBlock", {
	images: { "block_corner.png" }
	align: "center"
	hitbox: true
	collTag: "oh"
	collList: {
		ground: 'cross'
	}
	collFilter: (item, other) =>
		if other.tag == "Player"
			@move!
	move: () =>
		if not @moving
			@moving = true
			
}