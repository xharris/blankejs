PIXI.scaleModes.DEFAULT = PIXI.scaleModes.NEAREST;
class BlankePixi {
    constructor (opt) {
		opt = opt || { 
			w: window.innerWidth,
			h: window.innerHeight
		 }
		this.evt_list = {};

		this.can_drag = false;
        this.dragging = false;
		this.snap_on = false;
		this.mouse = [0,0];
        this.place_mouse = [0,0];
		this.half_mouse = [0,0];
		this.half_place_mouse = [0,0];
		this.lock_mouse = false;
        this.pointer_down = -1; 
		this.mx = 0;
		this.my = 0;
		this.snap = [32,32];
		this.snap_mouse = [0,0];
		this.camera = [0,0];
		//this.camera_start = [0,0];
		// Zoom control
		this.zoom = 1;
		this.zoom_target = 1;
		this.zoom_incr = 0.1;

        this.pixi = new PIXI.Application(opt.w, opt.h, {
            backgroundColor: opt.bg_color || 0x354048,
            antialias: false
        });
		this.pixi.stage.interactive = true;
		this.pixi.stage.hitArea = this.pixi.screen;
		this.pixi.view.addEventListener('contextmenu', (e) => {
			e.preventDefault();
		});
		
		// zoom
		window.addEventListener('wheel',(e)=>{
			/*
			e.preventDefault();
			this.setZoom(this.zoom - (Math.sign(e.deltaY) * this.zoom_incr))
			*/
		});

        // snap
        window.addEventListener('keydown', e => {
			var keyCode = e.keyCode || e.which;
			// CTRL
			if (keyCode == 17) {
                this.snap_on = true;
				this.dispatchEvent('snapChange',e);
			}		
			// moving camera with arrow keys
			if (document.activeElement === document.body) {
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

				this.setCameraPosition(this.camera[0] + vx, this.camera[1] + vy);

				// show camera grabbing hand
				if (e.key == "Alt") {
					this.pixi.view.style.cursor = "all-scroll";
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
			if (document.activeElement === document.body) {
				// CTRL
				if (keyCode == 17) {
					this.snap_on = false;
					this.dispatchEvent('snapChange',e);
				}
				this.pixi.view.style.cursor = "auto";
				if (e.key == "Escape") {
					this.dispatchEvent('keyCancel',e);
				}
				if (e.key == "Alt") {
					// release mouse
					this.camera_drag = false;
					this.dragStop();
					document.exitPointerLock();
				}
				if (e.key == "-") {
					// zoom out
					this.setZoom(this.zoom - this.zoom_incr);
				}
				if (e.key == "=") {
					// zoom out
					this.setZoom(this.zoom + this.zoom_incr);
				}
				if (e.key == "0") {
					// reset zoom
					this.setZoom(1);
				}
				if (e.key == "Delete" || e.key == "Backspace") {
					this.dispatchEvent('keyDelete',e);
				}
				// ENTER
				if (keyCode == 13) {
					this.dispatchEvent('keyFinish',e);
				}
			}
		});

        // mouse enter/exit
		this.pixi.view.addEventListener('mouseenter', e => {
			this.can_drag = true;
		});
		this.pixi.view.addEventListener('mouseout', e => {
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
					this.pixi.view.style.cursor = "all-scroll";
					this.camera_drag = true;
				}  
				this.can_drag = true;
			}
			this.dragStart();

			if (!alt && !this.camera_drag) {
                if (btn == 0)
					this.dispatchEvent('mousePlace',e);
                if (btn == 2) 
					this.dispatchEvent('mouseRemove',e);
			}
        });
        
		this.pixi.stage.on('pointerup', e => {
			let btn = e.data.originalEvent.button;
			let was_cam_dragging = this.camera_drag;
			if (this.dragging) {
				if (btn == 1) {
					this.pixi.view.style.cursor = "auto";
					this.camera_drag = false;
				} else 
				this.can_drag = true;
			}
			this.dragStop(was_cam_dragging);
        	this.pointer_down = -1;
		});

		this.pixi.stage.on('pointermove', e => {
			// mouse screen coordinates
			let x = e.data.global.x;
			let y = e.data.global.y;

			// camera dragging
			if (this.dragging) {
				if (this.camera_drag) {
					this.setCameraPosition(
						this.camera[0] + e.data.originalEvent.movementX,
						this.camera[1] + e.data.originalEvent.movementY
					)
				} else 
					this.dispatchEvent('dragMove');
			}

			let snapx = this.snap[0], snapy = this.snap[1];

			x /= this.zoom;
			y /= this.zoom;
				
			// mouse world coordinates
			let mx = x-(this.camera[0] / this.zoom),
				my = y-(this.camera[1] / this.zoom);
			this.mx = mx;
			this.my = my;

			this.place_mouse = [Math.floor(x * this.zoom),Math.floor(y * this.zoom)];
			this.mouse = [Math.floor(mx),Math.floor(my)];
			this.half_mouse = [Math.floor(mx), Math.floor(my)];
			this.half_place_mouse = [Math.floor(x),Math.floor(y)];

			// use: selecting images
			this.snap_mouse = [
				mx < 0 ? (mx - snapx - ((mx - snapx) % snapx)) : mx - (mx%snapx),
				my < 0 ? (my - snapy - ((my - snapy) % snapy)) : my - (my%snapy)
			]

			if (!e.data.originalEvent.ctrlKey && !this.camera_drag) { // !e.data.originalEvent.ctrlKey || ["object","image"].includes(this.obj_type)
				if (mx < 0) { mx -= snapx; x -= snapx; }
				if (my < 0) { my -= snapy; y -= snapy; }

				// use: placing images, displaying mouse coordinates
				this.mouse = [
					mx - (mx%snapx),
					my - (my%snapy)
				];
				// use: drawing crosshair
				this.place_mouse = [
					(x * this.zoom) - (mx % snapx  * this.zoom),
					(y * this.zoom) - (my % snapy * this.zoom)
				]

				if (mx < 0) { mx += snapx/2; x += snapx/2; }
				if (my < 0) { my += snapy/2; y += snapy/2; }
				// use: placing object points, displaying mouse coordinates
				this.half_mouse = [
					mx - (mx%(snapx/2)),
					my - (my%(snapy/2))
				];
				// use: drawing crosshair
				this.half_place_mouse = [
					(x * this.zoom) - (mx % (snapx/2.0)  * this.zoom),
					(y * this.zoom) - (my % (snapy/2.0) * this.zoom)
				]
			}
			this.dispatchEvent('mouseMove',e);
		});
	}
	updateZoom () {
		let diff = this.zoom_target - this.zoom;
		if (Math.abs(diff) < 0.01) {
			this.zoom = this.zoom_target;
			return;
		}
		 
		// look at https://github.com/anvaka/ngraph/tree/master/examples/pixi.js/03%20-%20Zoom%20And%20Pan instead

		requestAnimationFrame(this.updateZoom.bind(this));

		let old_s = this.zoom;
		let new_s = this.zoom + (diff / 10);
		let gw = (this.game_width / 2); 
		let gh = (this.game_height / 2);
		let offx = ((gw * new_s) - (gw * old_s));
		let offy = ((gh * new_s) - (gh * old_s));

		this.zoom = new_s;

		this.setCameraPosition(
			this.camera[0] - offx,
			this.camera[1] - offy
		);
		//this.refreshCamera();
		this.drawGrid();
	}
	setZoom (scale) {
		return; // TODO: zoom disabled for now
		
		this.zoom_target = scale > 0 ? scale : this.zoom;
		this.old_cam = [this.camera[0] * this.zoom, this.camera[1] * this.zoom];
		requestAnimationFrame(this.updateZoom.bind(this));
	}
	setCameraPosition (x, y) {
		this.camera = [x, y];
		this.dispatchEvent('cameraChange', {});
	}
	// Pointer Locking for camera dragging
	dragStart () {
		if (!this.dragging && this.can_drag) {
			this.dragging = true; 
			this.dispatchEvent('dragStart', { camera:this.camera_drag })
		}
	}
	dragStop (cam_drag_override) {
		if (this.dragging) {
			this.dragging = false;
			this.dispatchEvent('dragStop', { camera:cam_drag_override != null ? cam_drag_override : this.camera_drag });
		}
	}
	resize () {
		let parent = this.pixi.view.parentElement;
		if (!parent) return;
		let w = parent.clientWidth;
		let h = parent.clientHeight;
		this.pixi.renderer.view.style.width = w + "px";
		this.pixi.renderer.view.style.height = h + "px";
		//this part adjusts the ratio:
		this.pixi.renderer.resize(w,h);
	}
	get width () { return parseInt(this.pixi.renderer.view.clientWidth); }
	get height () { return parseInt(this.pixi.renderer.view.clientHeight); }
    get view () { return this.pixi.view; }
	get stage () { return this.pixi.stage; }
	get renderer () { return this.pixi.renderer; }
	on (name, fn) {
		if (!(name in this.evt_list)) this.evt_list[name] = [];
		if (!this.evt_list[name].includes(fn)) this.evt_list[name].push(fn);
	}
	dispatchEvent (name, e) {
		let x = e && e.data ? e.data.global.x : 0;
		let y = e && e.data ? e.data.global.y : 0;
		let btn = this.pointer_down;
		let alt = e && e.data ? e.data.originalEvent.altKey : false;
		let ctrl = e && e.data ? e.data.originalEvent.ctrlKey : false;
		const info = { x, y, btn, alt, ctrl, 
			mx:this.mx, my:this.my, mouse:this.mouse, 
			snap_mouse:this.snap_mouse, half_mouse:this.half_mouse
		}; 
		if (this.evt_list[name]) {
			for (let fn of this.evt_list[name])
				fn(e, info);
		}
	}
}