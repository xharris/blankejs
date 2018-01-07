function ifndef (in_var, value) {
	if(in_var == undefined) return value;
	else return in_var;
}

var BlankE = {
	app: null,
	objects: {},
	run: function (width, height) {
		BlankE.app = new PIXI.Application({
			width: width,
			height: height,
		});
		document.body.appendChild(BlankE.app.view);

		PIXI.loader.add(["assets/boss.png"]);

		PIXI.loader.load(BlankE._init);

	},

	_init: function() {
		BlankE.is_loaded = true;
		if (BlankE.init) BlankE.init();

		// start game loop
		BlankE.app.ticker.add(delta => BlankE._update(delta));
	},

	addGameObject: function(obj) {
		var obj_type = obj.constructor.name;
		BlankE.objects[obj_type] = ifndef(BlankE.objects[obj_type], []);
		BlankE.objects[obj_type].push(obj);
	},

	_update: function(dt) {
		if (BlankE.update) BlankE.update(dt);

		// iterate game objects
		for (var obj_type in BlankE.objects) {
			for (var o = 0; o < BlankE.objects[obj_type].length; o++) {
				var obj = BlankE.objects[obj_type][o];
				if (obj._update) obj._update(dt);
			}
		}
	}
}

class Entity {
	constructor () {
		this.x = 0;
		this.y = 0;
		this.sprites = {};
		this._sprite_index = '';

		BlankE.addGameObject(this);
	}

	addSprite (name='',path='') {
		this.sprites[name] = new PIXI.Sprite(PIXI.loader.resources[path].texture);
		BlankE.app.stage.addChild(this.sprites[name]);
	}

	set sprite_index (index) {
		this._sprite_index = index;

		// hide all sprites
		for (var spr in this.sprites) {
			this.sprites[spr].visible = false;
		}

		// show current sprite
		if (index in this.sprites) {
			this.sprites[index].visible = true;
		}
	}

	_update (dt) {
		var curr_sprite = this.sprites[this._sprite_index];
		curr_sprite.x = this.x;
		curr_sprite.y = this.y;
	}
}