class MapEditor extends Editor {
	constructor (...args) {
		super(...args);

		var this_ref = this;
		
		this.grid_opacity = 0.1;
		this.snap_on = true;

		this.curr_layer = null;
		this.curr_object = null;
		this.layers = [];
		this.objects = [];

		this.can_drag = false;
		this.dragging = false;
		this.mouse_start = [0,0];
		this.camera_start = [0,0];
		this.camera = [0,0];

		this.pixi = new PIXI.Application(800, 600, {
			backgroundColor: 0xFFFFFF,
			antialias: false,
			autoResize: true,
		});
		this.appendChild(this.pixi.view);

		// start game loop
		this.pixi.ticker.add(delta => this.update(delta)); 

		this.pixi.stage.interactive = true;
		this.pixi.stage.hitArea = this.pixi.screen;

		// create map container
		this.overlay_container = new PIXI.Container();
		this.map_container = new PIXI.Container();
		this.pixi.stage.addChild(this.map_container);

		this.grid_container = new PIXI.Container()
		this.grid_graphics = new PIXI.Graphics();
		this.origin_graphics = new PIXI.Graphics();

		this.grid_container.addChild(this.grid_graphics);
		this.overlay_container.addChild(this.origin_graphics);

		var el_br = app.createElement("br");

		// create sidebar
		this.el_sidebar 		= app.createElement("div","sidebar");

		this.el_object_container= app.createElement("div","object-container");
		this.el_input_letter 	= app.createElement("input","input-letter");
		this.el_sel_letter 		= app.createElement("select","select-letter");
		this.el_input_name		= app.createElement("input","input-name");
		this.el_btn_add_object	= app.createElement("button","btn-add-object");
		this.el_color_object	= app.createElement("input","color-object");
	
		this.el_layer_container	= app.createElement("div","layer-container");
		this.el_layer_name	 	= app.createElement("input","input-layer");
		this.el_sel_layer 		= app.createElement("select","select-layer");
		this.el_btn_add_layer	= app.createElement("button","btn-add-layer");
		this.el_snap_container	= app.createElement("div","snap-container");
		this.el_snap_label		= app.createElement("p","snap-label");
		this.el_snap_x			= app.createElement("input","snap-x");
		this.el_snap_y			= app.createElement("input","snap-y");
		this.el_snap_sep		= app.createElement("p","snap-sep");

		// object selector
		this.el_sel_letter.addEventListener('change', function(e){
			this_ref.setObject(e.target.value);
		});
		this.el_input_letter.maxLength = 1;
		this.el_input_letter.placeholder = '-';
		this.el_input_letter.addEventListener('input', function(e){
			if (this_ref.curr_object) {
				if (e.target.value == '')
					e.target.value = this_ref.curr_object.char;
				else {
					this_ref.curr_object.char = e.target.value;
					this_ref.iterObject(this_ref.curr_object.name, function(obj) {
						obj.text = this_ref.curr_object.char;
					});
				}
			}
		});
		this.el_input_letter.addEventListener('click', function(e){
			this.select();
		});

		// object name
		this.el_input_name.addEventListener('change', function(e){
			if (this_ref.curr_object) {
				if (e.target.value == '')
					e.target.value = this_ref.curr_object.name;
				else {
					this_ref.curr_object.name = e.target.value;
					this_ref.refreshObjectList();
				}
			}
		});

		// object color
		this.el_color_object.type = "color";
		this.el_color_object.addEventListener('change', function(e){
			if (this_ref.curr_object) {
				this_ref.curr_object.color = e.target.value;
				this_ref.iterObject(this_ref.curr_object.name, function(obj) {
					obj.style.fill = this_ref.curr_object.color;
				});
			}
		});

		// add object button
		this.el_btn_add_object.title = "add object";
		this.el_btn_add_object.innerHTML = "+";
		this.el_btn_add_object.addEventListener('click', function(e){
			this_ref.addObject();
		});

		// layer name
		this.el_sel_layer.addEventListener('change', function(e){
			this_ref.setLayer(e.target.value);
		});
		this.el_layer_name.addEventListener('input', function(e){
			if (this_ref.curr_layer) {
				if (e.target.value == '')
					e.target.value = this_ref.curr_layer.name;
				else {
					this_ref.curr_layer.name = e.target.value;
					this_ref.refreshLayerList();
				}
			}
		});
		this.el_layer_name.addEventListener('click', function(e){
			this.select();
		});

		// add layer button
		this.el_btn_add_layer.title = "add layer";
		this.el_btn_add_layer.innerHTML = "+";
		this.el_btn_add_layer.addEventListener('click', function(e){
			this_ref.addLayer();
		});

		// layer snap
		this.el_snap_label.innerHTML = "snap";
		this.el_snap_sep.innerHTML = "x";
		this.el_snap_x.value = 32;
		this.el_snap_y.value = 32;
		this.el_snap_x.addEventListener('input', function(e){
			var new_val = parseInt(e.target.value);
			if (new_val <= 0) new_val = this_ref.curr_layer.snap[0];
			this_ref.curr_layer.snap[0] = new_val;

			// move grid
			this_ref.grid_container.x = this_ref.camera[0] % this_ref.curr_layer.snap[0];
			this_ref.grid_container.y = this_ref.camera[1] % this_ref.curr_layer.snap[1];

			this_ref.iterObjectInLayer(this_ref.curr_layer.uuid, function(obj) {
				if (obj.snapped) {
					obj.x = obj.grid_x * this_ref.curr_layer.snap[0];
					obj.x = obj.x + (this_ref.curr_layer.snap[0]/2) - (obj.width/2);
				}
			});
			this_ref.drawGrid();
		});
		this.el_snap_y.addEventListener('input', function(e){
			var new_val = parseInt(e.target.value);
			if (new_val <= 0) new_val = this_ref.curr_layer.snap[1];
			this_ref.curr_layer.snap[1] = new_val;

			// move grid
			this_ref.grid_container.x = this_ref.camera[0] % this_ref.curr_layer.snap[0];
			this_ref.grid_container.y = this_ref.camera[1] % this_ref.curr_layer.snap[1];

			this_ref.iterObjectInLayer(this_ref.curr_layer.uuid, function(obj) {
				obj.style.fontSize = this_ref.curr_layer.snap[1]; // only for y snap change;
				if (obj.snapped) {
					obj.x = obj.grid_x * this_ref.curr_layer.snap[0];
					obj.x = obj.x + (this_ref.curr_layer.snap[0]/2) - (obj.width/2);

					obj.y = obj.grid_y * this_ref.curr_layer.snap[1];
					obj.y = obj.y + (this_ref.curr_layer.snap[1]/2) - (obj.height/2);
				}
			});
			
			this_ref.drawGrid();
		});

		this.el_snap_container.appendChild(this.el_snap_label);
		this.el_snap_container.appendChild(this.el_snap_x);
		this.el_snap_container.appendChild(this.el_snap_sep);
		this.el_snap_container.appendChild(this.el_snap_y);

		this.el_layer_container.appendChild(this.el_layer_name);
		this.el_layer_container.appendChild(this.el_sel_layer);
		this.el_layer_container.appendChild(this.el_btn_add_layer);
		this.el_layer_container.appendChild(this.el_snap_container);

		this.el_object_container.appendChild(this.el_input_letter);
		this.el_object_container.appendChild(this.el_sel_letter);
		this.el_object_container.appendChild(this.el_btn_add_object);
		this.el_object_container.appendChild(this.el_input_name);
		this.el_object_container.appendChild(this.el_color_object);

		this.el_sidebar.appendChild(this.el_object_container);
		this.el_sidebar.appendChild(this.el_layer_container);
		this.appendChild(this.el_sidebar);

		this.addLayer();
		this.addObject();

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

			// CTRL
			if (keyCode == 17) {
				this_ref.snap_on = false;
			}
		});
		window.addEventListener('keyup', function(e){
			var keyCode = e.keyCode || e.which;

			// SPACE
			if (keyCode == 32) {
				dragStop();
			}

			// CTRL
			if (keyCode == 17) {
				this_ref.snap_on = true;
			}
		});
		this.dragbox.drag_content.addEventListener('mouseenter', function(e){
			this_ref.can_drag = true;
		});
		this.dragbox.drag_content.addEventListener('mouseout', function(e){
			if (!this_ref.dragging) this_ref.can_drag = false;
		});
		this.pixi.stage.pointerdown = function(e){
			// dragging canvas
			if (e.data.button == 1 && !this_ref.dragging) {
				this_ref.can_drag = true;
				dragStart();
			}

			// placing object
			if (e.data.button == 0) {
				this_ref.placeObject(e.data.global.x - this_ref.camera[0], e.data.global.y - this_ref.camera[1]);
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
				this_ref.grid_container.x = this_ref.camera[0] % this_ref.curr_layer.snap[0];
				this_ref.grid_container.y = this_ref.camera[1] % this_ref.curr_layer.snap[1];

				this_ref.drawOrigin();
			}
		}


		this.pixi.stage.addChild(this.overlay_container);
		this.pixi.stage.addChild(this.map_container);
		this.pixi.stage.addChild(this.grid_container);

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
		var snapx = this.curr_layer.snap[0];
		var snapy = this.curr_layer.snap[1];
		var stage_width =  this.width;
		var stage_height = this.height;

		if (!this.grid_graphics) {
			this.grid_graphics = new PIXI.Graphics();
			this.grid_container.addChild(this.grid_graphics);
		}

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
		var snapx = this.curr_layer.snap[0];
		var snapy = this.curr_layer.snap[1];
		var stage_width =  this.width;
		var stage_height = this.height;

		if (!this.origin_graphics) {
			this.origin_graphics = new PIXI.Graphics();
			this.overlay_container.addChild(this.origin_graphics);
		}

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

	// refreshes combo box
	refreshLayerList () {
		app.clearElement(this.el_sel_layer);
		var placeholder = app.createElement("option");
		placeholder.selected = true;
		placeholder.disabled = true;
		this.el_sel_layer.appendChild(placeholder);

		for (var o = 0; o < this.layers.length; o++) {
			var new_option = app.createElement("option");
			new_option.value = this.layers[o].name;
			new_option.innerHTML = this.layers[o].name;
			this.el_sel_layer.appendChild(new_option);
		}	
	}

	// refreshes combo box 
	refreshObjectList () {
		app.clearElement(this.el_sel_letter);
		var placeholder = app.createElement("option");
		placeholder.selected = true;
		placeholder.disabled = true;
		this.el_sel_letter.appendChild(placeholder);

		for (var o = 0; o < this.objects.length; o++) {
			var new_option = app.createElement("option");
			new_option.value = this.objects[o].name;
			new_option.innerHTML = this.objects[o].name;
			this.el_sel_letter.appendChild(new_option);
		}
	}

	placeObject (x, y) {
		var this_ref = this;

		if (this.curr_object) {
			var new_text = new PIXI.Text(this.curr_object.char,{
				fontFamily: 'ProggySquare', 
				fill: this.curr_object.color,
				align: 'center',
				fontSize: this.curr_layer.snap[1]
			});

			if (this.snap_on) {
				x -= x % this.curr_layer.snap[0];
				y -= y % this.curr_layer.snap[1];
				new_text.snapped = true;
			}

			var text_key = Math.floor(x / this.curr_layer.snap[0]).toString()+','+Math.floor(y / this.curr_layer.snap[1]).toString()+'.'+this.curr_layer.uuid;
			if (this.curr_object.pixi_texts[text_key]) this.curr_object.pixi_texts[text_key].destroy();
			
			new_text.grid_x = Math.floor(x / this.curr_layer.snap[0]);
			new_text.grid_y = Math.floor(y / this.curr_layer.snap[1]);

			new_text.x += x + (this.curr_layer.snap[0]/2) - (new_text.width/2);
			new_text.y += y + (this.curr_layer.snap[1]/2) - (new_text.height/2);
			new_text.uuid = this.curr_object.uuid;
			new_text.text_key = text_key;
			new_text.layer_uuid = this.curr_layer.uuid;

			new_text.interactive = true;
			new_text.on('rightdown', function(e){
				if (e.target.layer_uuid === this_ref.curr_layer.uuid) {
					this_ref.curr_object.pixi_texts[e.target.text_key].destroy();
					this_ref.curr_object.pixi_texts[e.target.text_key] = null;
				}
			});
			
			var new_graph = new PIXI.Graphics();
			new_graph.beginFill(0x0000FF, 0);
			new_graph.drawRect(-((this.curr_layer.snap[0]/2) - (new_text.width/2)), -((this.curr_layer.snap[1]/2) - (new_text.height/2)), this.curr_layer.snap[0], this.curr_layer.snap[1]);
			new_text.addChild(new_graph);
			
			this.curr_object.pixi_texts[text_key] = new_text;
			this.curr_layer.container.addChild(new_text);
		}
	}

	iterObject (name, func) {
		for (var l = 0; l < this.objects.length; l++) {
			if (this.objects[l].name === name) {
				var new_array = {};
				for (var t in this.objects[l].pixi_texts) {
					if (this.objects[l].pixi_texts[t]) {
						func(this.objects[l].pixi_texts[t], t);
						new_array[t] = this.objects[l].pixi_texts[t];
					}
				}
				this.objects[l].pixi_texts = new_array;
				return;
			}
		}
	}

	iterObjectInLayer (layer_uuid, func) {
		for (var l = 0; l < this.objects.length; l++) {
			var new_array = {};
			for (var t in this.objects[l].pixi_texts) {
				if (this.objects[l].pixi_texts[t] && this.objects[l].pixi_texts[t].layer_uuid == layer_uuid) {
					func(this.objects[l].pixi_texts[t], t);
					new_array[t] = this.objects[l].pixi_texts[t];
				}
			}
			this.objects[l].pixi_texts = new_array;
			return;
		}		
	}

	// https://stackoverflow.com/questions/1349404/generate-random-string-characters-in-javascript
	addObject (info) {
		var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%<>?&+=";
		var obj_name = 'object'+this.objects.length;
		info = info || {
			name: obj_name,
			char: possible.charAt(Math.floor(Math.random() * possible.length)),
			color: "#000000",
			uuid: guid(),
			pixi_texts: {}
		}
		this.objects.push(info);
		this.setObject(obj_name);

		this.refreshObjectList();
	}

	setObject (name) {
		for (var l = 0; l < this.objects.length; l++) {
			if (this.objects[l].name === name) {
				this.curr_object = this.objects[l];
				this.el_input_letter.value = this.curr_object.char;
				this.el_input_name.value = this.curr_object.name;
				return;
			}
		}	
	}

	addLayer (info) {
		var layer_name = 'layer'+this.layers.length;
		info = info || {
			name: layer_name,
			depth: 0,
			offset: [0, 0],
			snap: [32, 32],
			uuid: guid()
		}
		info.container = new PIXI.Container();
		this.map_container.addChild(info.container);
		this.layers.push(info);
		this.setLayer(layer_name);

		this.refreshLayerList();
	}

	setLayer (name) {
		for (var l = 0; l < this.layers.length; l++) {
			if (this.layers[l].name === name) {
				this.curr_layer = this.layers[l];
				this.el_layer_name.value = this.curr_layer.name;
				this.el_snap_x.value = this.curr_layer.snap[0];
				this.el_snap_y.value = this.curr_layer.snap[1];
				this.layers[l].container.alpha = 1;

				this.map_container.setChildIndex(this.layers[l].container, this.map_container.children.length-1);
			} else {
				// make other layers transparent
				this.layers[l].container.alpha = 0.25;
			}
		}
		this.drawGrid();
	}

	load (filename) {

	}

	export () {

	}

	update (dt) {

	}
}

document.addEventListener("ideReady", function(e){
	/*app.addSearchKey({
		key: 'Create map',
		onSelect: func
	});*/
});