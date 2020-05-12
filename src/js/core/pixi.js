PIXI.settings.SCALE_MODE = PIXI.SCALE_MODES.NEAREST;
PIXI.Loader.shared.add("ProggyScene", "src/includes/proggy_scene.fnt");
PIXI.Loader.shared.load();

// http://www.html5gamedevs.com/topic/7507-how-to-move-the-sprite-to-the-top/?do=findComment&comment=45162
function bringToFront(sprite, parent) {
	var sprite = typeof sprite != "undefined" ? sprite.target || sprite : this;
	var parent = parent || sprite.parent || { children: false };
	if (parent.children) {
		for (var keyIndex in sprite.parent.children) {
			if (sprite.parent.children[keyIndex] === sprite) {
				sprite.parent.children.splice(keyIndex, 1);
				break;
			}
		}
		parent.children.push(sprite);
	}
}
function sendToBack(sprite, parent) {
	var sprite = typeof sprite != "undefined" ? sprite.target || sprite : this;
	var parent = parent || sprite.parent || { children: false };
	if (parent.children) {
		for (var keyIndex in sprite.parent.children) {
			if (sprite.parent.children[keyIndex] === sprite) {
				sprite.parent.children.splice(keyIndex, 1);
				break;
			}
		}
		parent.children.splice(0, 0, sprite);
	}
}

let clientX = 0, clientY = 0;
class BlankePixi {
	constructor(opt) {
		opt = opt || {
			w: window.innerWidth,
			h: window.innerHeight,
			zoom_clamp: [0.1, 15]
		}
		this.options = opt;
		this.evt_list = {};

		this.can_drag = false;
		this.dragging = false;
		this.snap_on = false;
		this.real_mouse = [0, 0]
		this.mouse = [0, 0];
		this.place_mouse = [0, 0];
		this.half_mouse = [0, 0];
		this.half_place_mouse = [0, 0];
		this.lock_mouse = false;
		this.pointer_down = -1;
		this.mx = 0;
		this.my = 0;
		this.snap = [32, 32];
		this.snap_mouse = [0, 0];
		this.camera = [0, 0];
		this.camera_bounds = null;
		//this.camera_start = [0,0];
		// Zoom control
		this.zoom = 1;
		this.zoom_target = 1;
		this.zoom_incr = 0.5;

		this.pixi = new PIXI.Application({
			width: opt.w,
			height: opt.h,
			backgroundColor: opt.bg_color || 0x354048,
			antialias: false
		});
		this.pixi.stage.interactive = true;
		this.pixi.stage.hitArea = this.pixi.screen;
		this.pixi.view.addEventListener('contextmenu', (e) => {
			e.preventDefault();
		});

		this.renderer.state.blendModes[21] = [WebGLRenderingContext.ONE, WebGLRenderingContext.ONE,
		WebGLRenderingContext.ONE, WebGLRenderingContext.ONE,
		WebGLRenderingContext.FUNC_REVERSE_SUBTRACT, WebGLRenderingContext.FUNC_ADD];
		// used to erase using graphics
		this.renderer.state.blendModes[22] = [0, WebGLRenderingContext.ONE_MINUS_SRC_ALPHA];

		this.has_mouse = true;

		// zoom
		window.addEventListener('wheel', (e) => {
			if (this.has_mouse) {
				// e.preventDefault();
				//console.log( - (Math.sign(e.deltaY) * (this.zoom_incr * (this.zoom))));
				this.setZoom(this.zoom - (Math.sign(e.deltaY) * (this.zoom_incr * (this.zoom))))
			}
		});

		// snap
		window.addEventListener('keydown', e => {
			var keyCode = e.keyCode || e.which;
			// CTRL
			if (keyCode == 17) {
				this.snap_on = true;
				this.dispatchEvent('snapChange', e);
			}
			// moving camera with arrow keys
			if (this.has_mouse) {
				this.dispatchEvent('keyDown', e);
				var keyCode = e.keyCode || e.which;
				let vx = 0;
				let vy = 0;
				// left
				if (keyCode == 37) vx = this.snap[0];
				// right
				if (keyCode == 39) vx = -this.snap[0];
				// up
				if (keyCode == 38) vy = this.snap[1];
				// down
				if (keyCode == 40) vy = -this.snap[1];

				this.moveCamera(vx, vy);

				// show camera grabbing hand
				if (e.key == "Alt") {
					this.pixi.stage.cursor = "all-scroll";
					this.pixi.view.requestPointerLock();
					this.camera_drag = true;
					this.dragStart();
				}

				/* TODO: cancel things 
				if (e.key == "Esc") {
        			this.pointer_down = -1;

        			// ... like placing tiles in a line
				}*/
			}
		});

		window.addEventListener('keyup', e => {
			var keyCode = e.keyCode || e.which;
			if (e.key == "Alt") {
				// release mouse
				this.camera_drag = false;
				this.dragStop();
				document.exitPointerLock();
			}

			if (this.has_mouse) {
				this.dispatchEvent('keyUp', e);
				// CTRL
				if (keyCode == 17) {
					this.snap_on = false;
					this.dispatchEvent('snapChange', e);
				}
				this.pixi.stage.cursor = this._hide_mouse ? "none" : "auto";
				if (e.key == "Escape") {
					this.dispatchEvent('keyCancel', e);
				}
				if (e.key == "Alt") {
				}
				if (e.ctrlKey && e.key == "-") {
					// zoom out
					this.setZoom(this.zoom - (this.zoom_incr * (this.zoom)));
				}
				if (e.ctrlKey && e.key == "=") {
					// zoom in
					this.setZoom(this.zoom + (this.zoom_incr * (this.zoom)));
				}
				if (e.key == "0") {
					if (e.ctrlKey)
						// reset camera position
						this.setCameraPosition(0, 0);
					else
						// reset zoom
						this.setZoom(1);
				}
				if (e.key == "Delete" || e.key == "Backspace") {
					this.dispatchEvent('keyDelete', e);
				}
				// ENTER
				if (keyCode == 13) {
					this.dispatchEvent('keyFinish', e);
				}
			}
		});

		// mouse enter/exit
		this.pixi.view.addEventListener('mouseenter', e => {
			this.has_mouse = true;
			this.dispatchEvent('mouseEnter', e);
			this.can_drag = true;
		});
		this.pixi.view.addEventListener('mouseout', e => {
			this.has_mouse = false;
			this.dispatchEvent('mouseOut', e);
			if (!this.dragging) {
				this.can_drag = false;
			}
		});

		// general mouse events
		this.pixi.stage.on('pointerdown', e => {
			let btn = e.data.originalEvent.button;
			let alt = e.data.originalEvent.altKey;
			this.pointer_down = btn;

			// dragging canvas
			if (!this.dragging) {
				if (btn == 1) {
					this.pixi.stage.cursor = "all-scroll";
					this.camera_drag = true;
				}
				this.can_drag = true;
			}
			this.dragStart();

			if (!alt && !this.camera_drag) {
				if (btn == 0)
					this.dispatchEvent('mousePlace', e);
				if (btn == 2)
					this.dispatchEvent('mouseRemove', e);
			}
			this.dispatchEvent('mouseDown', e);
		});

		this.pixi.stage.on('pointerup', e => {
			let btn = e.data.originalEvent.button;
			let was_cam_dragging = this.camera_drag;
			if (this.dragging) {
				if (btn == 1) {
					this.camera_drag = false;
				} else
					this.can_drag = true;
			}
			this.dragStop(was_cam_dragging);
			this.dispatchEvent('mouseUp', e);
			this.pointer_down = -1;
			this.pixi.stage.cursor = this._hide_mouse ? "none" : "auto";
		});

		this.pixi.stage.on('pointermove', e => {
			// mouse screen coordinates
			let x = e.data.global.x;
			let y = e.data.global.y;

			// camera dragging
			if (this.dragging) {
				if (this.camera_drag) {
					this.moveCamera(e.data.originalEvent.movementX, e.data.originalEvent.movementY);
				} else
					this.dispatchEvent('dragMove');
			}

			let snapx = this.snap[0], snapy = this.snap[1];

			x /= this.zoom;
			y /= this.zoom;

			// mouse world coordinates
			let mx = x - (this.camera[0] / this.zoom),
				my = y - (this.camera[1] / this.zoom);
			this.mx = mx;
			this.my = my;

			this.place_mouse = [Math.floor(x * this.zoom), Math.floor(y * this.zoom)]

			this.real_mouse = [Math.floor(x * this.zoom), Math.floor(y * this.zoom)]
			this.mouse = [Math.floor(mx), Math.floor(my)];
			this.half_mouse = [Math.floor(mx), Math.floor(my)];
			this.half_place_mouse = [Math.floor(x), Math.floor(y)];

			// use: selecting images
			this.snap_mouse = [
				mx < 0 ? (mx - snapx - ((mx - snapx) % snapx)) : mx - (mx % snapx),
				my < 0 ? (my - snapy - ((my - snapy) % snapy)) : my - (my % snapy)
			]


			if (!e.data.originalEvent.ctrlKey && !this.camera_drag) { // !e.data.originalEvent.ctrlKey || ["object","image"].includes(this.obj_type)
				if (mx < 0) { mx -= snapx; x -= snapx; }
				if (my < 0) { my -= snapy; y -= snapy; }

				// use: placing images, displaying mouse coordinates
				this.mouse = [
					mx - (mx % snapx),
					my - (my % snapy)
				];
				// use: drawing crosshair
				this.place_mouse = [
					(x * this.zoom) - (mx % snapx * this.zoom),
					(y * this.zoom) - (my % snapy * this.zoom)
				]

				if (mx < 0) { mx += snapx / 2; x += snapx / 2; }
				if (my < 0) { my += snapy / 2; y += snapy / 2; }
				// use: placing object points, displaying mouse coordinates
				this.half_mouse = [
					mx - (mx % (snapx / 2)),
					my - (my % (snapy / 2))
				];
				// use: drawing crosshair
				this.half_place_mouse = [
					(x * this.zoom) - (mx % (snapx / 2.0) * this.zoom),
					(y * this.zoom) - (my % (snapy / 2.0) * this.zoom)
				]
			}
			this.dispatchEvent('mouseMove', e);
		});
	}
	set hide_mouse(v) {
		this._hide_mouse = v;
		this.pixi.stage.cursor = this._hide_mouse ? "none" : "auto";
	}
	bringToFront(sprite, parent) { var sprite = (typeof (sprite) != "undefined") ? sprite.target || sprite : this; var parent = parent || sprite.parent || { "children": false }; if (parent.children) { for (var keyIndex in sprite.parent.children) { if (sprite.parent.children[keyIndex] === sprite) { sprite.parent.children.splice(keyIndex, 1); break; } } parent.children.push(sprite); } }
	sendToBack(sprite, parent) { var sprite = (typeof (sprite) != "undefined") ? sprite.target || sprite : this; var parent = parent || sprite.parent || { "children": false }; if (parent.children) { for (var keyIndex in sprite.parent.children) { if (sprite.parent.children[keyIndex] === sprite) { sprite.parent.children.splice(keyIndex, 1); break; } } parent.children.splice(0, 0, sprite); } }
	orderComponents(list) {
		for (let el of list) {
			this.bringToFront(el);
		}
	}
	updateZoom() {
		let diff = this.zoom_target - this.zoom;
		if (Math.abs(diff) < 0.01) {
			this.zoom = this.zoom_target;
			this.dispatchEvent('zoomChange', { zoom: this.zoom });
			this.refreshCornerText()
			return;
		} else {
			this.dispatchEvent('zoomChanging', { zoom: this.zoom });
			this.refreshCornerText()
		}

		// look at https://github.com/anvaka/ngraph/tree/master/examples/pixi.js/03%20-%20Zoom%20And%20Pan instead

		var getCoords = (() => {
			var ctx = {
				global: { x: 0, y: 0 } // store it inside closure to avoid GC pressure
			};

			return (container, x, y) => {
				ctx.global.x = x; ctx.global.y = y;
				return PIXI.interaction.InteractionData.prototype.getLocalPosition.call(ctx, container);
			}
		})();

		requestAnimationFrame(this.updateZoom.bind(this));
		let new_s = this.zoom + (diff / 10);

		this.zoom = new_s;

		if (this.stage.children.length >= 1) {
			let child = this.stage.children[0];
			child.scale.x = this.zoom;
			child.scale.y = this.zoom;
			let rect = this.view.getBoundingClientRect();
			let beforeTrans = getCoords(child, clientX - rect.left, clientY - rect.top);
			child.updateTransform();
			let afterTrans = getCoords(child, clientX - rect.left, clientY - rect.top);
			this.moveCamera(
				(afterTrans.x - beforeTrans.x) * child.scale.x,
				(afterTrans.y - beforeTrans.y) * child.scale.y
			)
			child.updateTransform();
		}
	}
	setZoom(scale) {
		this.zoom_target = Math.min(Math.max(scale > 0 ? scale : this.options.zoom_clamp[0]), this.options.zoom_clamp[1]);
		this.old_cam = [this.camera[0] * this.zoom, this.camera[1] * this.zoom];
		requestAnimationFrame(this.updateZoom.bind(this));
	}
	moveCamera(dx, dy) {
		this.setCameraPosition(this.camera[0] + (dx), this.camera[1] + (dy));
		this.refreshCornerText()
	}
	getCameraPosition() { // needs work
		return [
			this.camera[0] / this.zoom,
			this.camera[1] / this.zoom
		]
	}
	setHelpText(text) {
		this.extra_help_text = text
		this.refreshCornerText()
	}
	setInfoText(text) {
		this.extra_info_text = text
		this.refreshCornerText()
	}
	getBitmapText(opts) {
		return new PIXI.extras.BitmapText(
			'',
			Object.assign({ font: { size: 16, name: "proggy_scene", align: "left" } }, opts || {})
		)
	}
	refreshCornerText() {
		if (!this.help_text) {
			this.help_text = this.getBitmapText()
			this.pixi.stage.addChild(this.help_text)
		}
		if (!this.info_text) {
			this.info_text = this.getBitmapText()
			this.pixi.stage.addChild(this.info_text)
		}

		const default_text = `${this.zoom != 1 ? `zoom: ${blanke.places(this.zoom, 2)}\n` : ''}MiddleClick/Alt = move camera, Ctrl-0 = reset camera, ${this.zoom != 1 ? "0 = reset zoom" : "Scroll = zoom"}`

		this.info_text.text = this.extra_info_text
		if (app.ideSetting("show_help_text") == true)
			this.help_text.text = (this.extra_help_text || "") + "\n" + default_text
		else
			this.help_text.text = this.zoom != 1 ? `zoom: ${blanke.places(this.zoom, 2)}` : ''
		this.help_text.alpha = 0.6;

		const margin = 20;
		const status_bar_height = 22;
		this.help_text.x = margin
		this.help_text.y = this.height - this.help_text.height - margin - status_bar_height;

		this.info_text.x = margin
		this.info_text.y = this.help_text.y - this.info_text.height
		if (this.help_text.height > 0)
			this.info_text.y -= (margin / 2)

		this.bringToFront(this.help_text)
	}
	bringToFront(sprite) {
		bringToFront(sprite)
		if (this.help_text)
			bringToFront(this.help_text)
		if (this.info_text)
			bringToFront(this.info_text)
	}
	sendToBack(sprite) {
		sendToBack(sprite)
		if (this.help_text)
			bringToFront(this.help_text)
		if (this.info_text)
			bringToFront(this.info_text)
	}
	setCameraPosition(x, y) {
		let xclamp = [x, x];
		let yclamp = [y, y];
		if (this.camera_bounds) {
			let l = this.camera_bounds[0], t = this.camera_bounds[1];
			let w = this.camera_bounds[2], h = this.camera_bounds[3];
			let offx = w - (w * this.zoom),
				offy = h - (h * this.zoom);
			xclamp = [l + offx, w - offx];
			yclamp = [t + offy, h - offy];
		}
		this.camera[0] = Math.floor(Math.min(Math.max(x, xclamp[0]), xclamp[1]) + 0.5);
		this.camera[1] = Math.floor(Math.min(Math.max(y, yclamp[0]), yclamp[1]) + 0.5);
		this.dispatchEvent('cameraChange', { x, y });
	}
	setCameraBounds(x1, y1, x2, y2) {
		/*
		if (x1 != null)
			this.camera_bounds = [x1, y1, x2, y2];
		else
			this.camera_bounds = null;
		this.setCameraPosition(...this.camera);
		*/
	}
	// Pointer Locking for camera dragging
	dragStart() {
		if (!this.dragging && this.can_drag) {
			this.dragging = true;
			this.dispatchEvent('dragStart', { camera: this.camera_drag })
		}
	}
	dragStop(cam_drag_override) {
		if (this.dragging) {
			this.dragging = false;
			this.dispatchEvent('dragStop', { camera: cam_drag_override != null ? cam_drag_override : this.camera_drag });
		}
	}
	resize(cb) {
		if (!this.resizeTimeout)
			this.resizeTimeout = setTimeout(() => {
				let parent = this.pixi.view.parentElement;
				if (!parent) return;
				let w = parent.clientWidth;
				let h = parent.clientHeight;
				this.pixi.renderer.view.style.width = w + "px";
				this.pixi.renderer.view.style.height = h + "px";
				//this part adjusts the ratio:
				this.pixi.renderer.resize(w, h);
				this.refreshCornerText()

				if (cb) cb()

				this.resizeTimeout = null;
			}, 10)
	}
	get width() { return parseInt(this.pixi.renderer.view.clientWidth); }
	get height() { return parseInt(this.pixi.renderer.view.clientHeight); }
	get view() { return this.pixi.view; }
	get stage() { return this.pixi.stage; }
	get renderer() { return this.pixi.renderer; }
	get ticker() { return this.pixi.ticker; }
	get loader() { return PIXI.Loader.shared; }
	loadRes(path, cb, name) {
		if (!name) name = path;
		let loader = new PIXI.Loader();
		//if (!this.loader.resources[name]) {
		loader.add(name, path);
		loader.load(cb);
		//}
	}
	on(name, fn) {
		if (!(name in this.evt_list)) this.evt_list[name] = [];
		if (!this.evt_list[name].includes(fn)) this.evt_list[name].push(fn);
	}
	dispatchEvent(name, e) {
		let x = e && e.data ? e.data.global.x : 0;
		let y = e && e.data ? e.data.global.y : 0;
		let btn = this.pointer_down;
		let alt = e && e.data ? e.data.originalEvent.altKey : false;
		let ctrl = e && e.data ? e.data.originalEvent.ctrlKey : false;
		const info = {
			x, y, btn, alt, ctrl,
			mx: this.mx, my: this.my, mouse: this.mouse,
			snap_mouse: this.snap_mouse, half_mouse: this.half_mouse
		};
		if (this.evt_list[name]) {
			for (let fn of this.evt_list[name])
				fn(e, info);
		}
	}
}

window.addEventListener('mousemove', (e) => {
	clientX = e.clientX;
	clientY = e.clientY;
});