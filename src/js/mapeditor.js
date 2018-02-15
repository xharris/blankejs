class MapEditor extends Editor {
	constructor (...args) {
		super(...args);

		var this_ref = this;
		this.snapx = 32;
		this.snapy = 32;
		this.grid_opacity = 0.1;

		this.pixi = new PIXI.Application(800, 600, {
			backgroundColor: 0xFFFFFF,
			antialias: false,
			autoResize: true,
		});
		this.appendChild(this.pixi.view);

		// start game loop
		this.pixi.ticker.add(delta => this.update(delta));
		//console.log()

		// create map container
		this.overlay_container = new PIXI.Container();
		this.map_container = new PIXI.Container();
		this.pixi.stage.addChild(this.map_container);

		this.pixi.stage.interactive = true;
		this.pixi.stage.hitArea = this.pixi.screen;

		this.can_drag = false;
		this.dragging = false;
		this.mouse_start = [0,0];
		this.camera_start = [0,0];
		this.camera = [0,0];
		function dragStart() {
			if (!this_ref.dragging && this_ref.can_drag) {
				var mouse = this_ref.pixi.renderer.plugins.interaction.mouse.global;
				this_ref.mouse_start = {x:mouse.x, y:mouse.y};
				this_ref.camera_start = this_ref.camera;
				this_ref.dragging = true;
			}
		}
		function dragStop() {
			if (this_ref.dragging) {
				this_ref.dragging = false;
			}
		}
		window.addEventListener('keydown', function(e){
			var keyCode = e.keyCode || e.which;

			// SPACE
			if (keyCode == 32) {
				dragStart();
			}
		});
		window.addEventListener('keyup', function(e){
			var keyCode = e.keyCode || e.which;

			// SPACE
			if (keyCode == 32) {
				dragStop();
			}
		});
		this.dragbox.drag_content.addEventListener('mouseenter', function(e){
			this_ref.can_drag = true;
		});
		this.dragbox.drag_content.addEventListener('mouseout', function(e){
			this_ref.can_drag = false;
		});
		this.pixi.stage.pointerdown = function(e){
			if (e.data.button == 1 && !this_ref.dragging) {
				dragStart();
			}
		}
		document.addEventListener('mouseup', function(e) {
			if (e.button == 1) {
				dragStop();
			}
		});
		this.pixi.stage.pointermove = function(e) {
			if (this_ref.dragging) {
				this_ref.camera = [
					this_ref.camera_start[0] + (e.data.global.x - this_ref.mouse_start.x) ,
					this_ref.camera_start[1] + (e.data.global.y - this_ref.mouse_start.y) 
				];
				this_ref.map_container.setTransform(this_ref.camera[0], this_ref.camera[1]);

				// move grid
				this_ref.grid_container.x = this_ref.camera[0] % this_ref.snapx;
				this_ref.grid_container.y = this_ref.camera[1] % this_ref.snapy;

				this_ref.drawOrigin();
			}
		}

		this.grid_container = new PIXI.Container()
		this.grid_graphics = new PIXI.Graphics();
		this.origin_graphics = new PIXI.Graphics();

		this.grid_container.addChild(this.grid_graphics);
		this.overlay_container.addChild(this.origin_graphics);

		this.pixi.stage.addChild(this.overlay_container);
		this.pixi.stage.addChild(this.map_container);
		this.pixi.stage.addChild(this.grid_container);

		this.drawGrid();
		this.addCallback('onResize', function(w, h) {
			this_ref.drawGrid();
		});
	}

	onMenuClick (e) {
		var this_ref = this;
		app.contextMenu(e.x, e.y, [
			{label:'rename', click:function(){}},//this_ref.renameModal()}},
			{label:'delete', click:function(){}}//this_ref.deleteModal()}}
		]);
	}

	drawGrid () {	
		var snapx = this.snapx;
		var snapy = this.snapy;
		var stage_width =  this.width;
		var stage_height = this.height;

		this.grid_graphics.clear();
		this.grid_graphics.lineStyle(1, 0x000000, this.grid_opacity);
		// vertical lines
		for (var x = -snapx; x < stage_width + snapx; x += snapx) {
			this.grid_graphics.moveTo(x, -snapy);
			this.grid_graphics.lineTo(x, stage_height + snapy);
		}
		// horizontal lines
		for (var y = -snapy; y < stage_height + snapy; y += snapy) {
			this.grid_graphics.moveTo(-snapx, y);
			this.grid_graphics.lineTo(stage_width + snapx, y);
		}

		this.drawOrigin();
	}

	drawOrigin () {
		var snapx = this.snapx;
		var snapy = this.snapy;
		var stage_width =  this.width;
		var stage_height = this.height;

		// origin line
		this.origin_graphics.clear()
		this.origin_graphics.lineStyle(3, 0x000000, this.grid_opacity);

		// horizontal
		this.origin_graphics.moveTo(0, this.camera[1])
		this.origin_graphics.lineTo(stage_width, this.camera[1]);
		// vertical
		this.origin_graphics.moveTo(this.camera[0], 0);
		this.origin_graphics.lineTo(this.camera[0], stage_height);
	}

	load () {

	}

	update (dt) {

	}
}