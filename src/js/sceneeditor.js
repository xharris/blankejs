var global_objects = [];

class SceneEditor extends Editor {
	constructor (...args) {
		super(...args);
		this.setupTab();

		var this_ref = this;

		this.file = '';
		this.map_folder = '/maps';
		
		this.grid_opacity = 0.1;
		this.snap_on = true;
		this.deleted = false;

		this.obj_type = '';
		this.curr_layer = null;
		this.curr_object = null;	// reference from this.objects[]
		this.curr_image	= null;		// reference from this.images[]
		this.layers = [];
		this.objects = [];			// all objects placed on the canvas
		this.images = [];			// placeable images in project folders {path, snap[x,y], pixi_images{}}

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

		// IMAGE elements
		this.el_image_form = new BlankeForm([
			['snap', 'number', {'inputs':2, 'separator':'X'}],
			['offset', 'number', {'inputs':2, 'separator':'X'}],
			['spacing', 'number', {'inputs':2, 'separator':'X'}]
		]);
		this.el_image_info 		= app.createElement("p","image-info");
		this.el_image_container	= app.createElement("div","image-container");
		this.el_image_tiles_container = app.createElement("div","image-tiles-container")
		this.el_image_preview	= app.createElement("img","image-preview");
		this.el_image_grid		= app.createElement("div","image-grid");

		// OBJECT elements
		this.el_object_container= app.createElement("div","object-container");
		this.el_input_letter 	= app.createElement("input","input-letter");
		this.el_sel_letter 		= app.createElement("select","select-letter");
		this.el_btn_add_object	= app.createElement("button","btn-add-object");

		this.el_object_form = new BlankeForm([
			['name', 'text', {'label':false}],
			['color', 'color', {'label':false}]
		]);
		this.el_input_name		= app.createElement("input","input-name");
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

		this.el_sel_placetype 	= app.createElement("select","select-placetype");
		this.el_sel_object		= app.createElement("select","select-object");
		this.el_input_object	= app.createElement("input","input-object");
		// add object types
		let obj_types = ['image','object']
		for (var o = 0; o < obj_types.length; o++) {
			var new_option = app.createElement("option");
			new_option.value = obj_types[o];
			new_option.innerHTML = obj_types[o];
			this.el_sel_placetype.appendChild(new_option);
		}
		this.el_sel_placetype.addEventListener('change', function(e){
			// populate object selection list
			this_ref.refreshObjectType();
		});

		// IMAGE elements
		this.refreshImageList();
		this.el_image_preview.ondragstart = function() { return false; };

		this.el_image_form.setValue('snap', 32, 0);
		this.el_image_form.setValue('snap', 32, 1);
		this.el_image_form.onChange('snap', function(value){
			let snapx = value[0];
			let snapy = value[1];

			if (this_ref.curr_image) {
				if (snapx > 0) this_ref.curr_image.snap[0] = snapx;
				if (snapy > 0) this_ref.curr_image.snap[1] = snapy;

				this_ref.refreshImageGrid();

				if (snapx <= 0 || snapy <= 0)
					return this_ref.curr_image.snap.slice();
			}
		});

		this.el_image_form.setValue('offset', 0, 0);
		this.el_image_form.setValue('offset', 0, 1);
		this.el_image_form.onChange('offset', function(value){
			let offsetx = value[0];
			let offsety = value[1];

			if (this_ref.curr_image) {
				if (offsetx > 0) this_ref.curr_image.offset[0] = offsetx;
				if (offsety > 0) this_ref.curr_image.offset[1] = offsety;

				this_ref.refreshImageGrid();

				if (offsetx <= 0 || offsety <= 0)
					return this_ref.curr_image.offset.slice();
			}
		});

		this.el_image_form.setValue('spacing', 0, 0);
		this.el_image_form.setValue('spacing', 0, 1);
		this.el_image_form.onChange('spacing', function(value){
			let spacingx = value[0];
			let spacingy = value[1];

			if (this_ref.curr_image) {
				if (spacingx > 0) this_ref.curr_image.spacing[0] = spacingx;
				if (spacingy > 0) this_ref.curr_image.spacing[1] = spacingy;

				this_ref.refreshImageGrid();

				if (spacingx <= 0 || spacingy <= 0)
					return this_ref.curr_image.spacing.slice();
			}
		});

		this.el_image_grid.ondragstart = function() { return false; };
		this.selected_image_frames = [];
		this.selected_xmin = -1;
		this.selected_ymin = -1;
		function selectImageTiles(e) {
			if (e.target && e.target.matches('div.cell') && e.buttons != 0) {
				if (e.buttons == 1) {
					// if CTRL is not held down, clear all other tiles
					if (!e.ctrlKey) {
						let el_tiles = document.querySelectorAll('.image-grid div.cell');
						for (let tile of el_tiles) {
							tile.classList.remove('selected');
						}
					}
					e.target.classList.add('selected');
				}
				if (e.buttons == 2) e.target.classList.remove('selected');
				this_ref.refreshImageSelectionList();
			}
		}
		this.el_image_grid.addEventListener('mousemove',selectImageTiles);
		this.el_image_grid.addEventListener('mousedown',selectImageTiles);

		// OBJECT elements
		this.el_sel_letter.addEventListener('change', function(e){
			this_ref.setObject(e.target.value);
		});
		this.el_input_letter.maxLength = 1;
		this.el_input_letter.placeholder = '-';

		// object char
		this.el_input_letter.addEventListener('input', function(e){
			if (this_ref.curr_object) {
				if (e.target.value == '')
					e.target.value = this_ref.curr_object.char;
				else {
					this_ref.curr_object.char = e.target.value;
					this_ref.iterObject(this_ref.curr_object.name, function(obj) {
						obj.text = this_ref.curr_object.char;
					});
					this_ref.updateGlobalObjList();
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
					this_ref.export();
					this_ref.updateGlobalObjList();
				}
			}
		});

		// object color
		this.el_color_object.type = "color";
		this.el_color_object.addEventListener('change', function(e){
			if (this_ref.curr_object) {
				this_ref.curr_object.color = e.target.value;
				this_ref.iterObject(this_ref.curr_object.name, function(obj) {
					let x = obj.x, y = obj.y;

					obj.clear();
					obj.beginFill(parseInt(this_ref.curr_object.color.replace('#',"0x"),16), .5);
					obj.drawCircle(obj.place_x, obj.place_y, obj.radius);
					obj.label.style.fill = this_ref.curr_object.color;
				});
				this_ref.export();
				this_ref.updateGlobalObjList();
			}
		});

		// add object button
		this.el_btn_add_object.title = "add object";
		this.el_btn_add_object.innerHTML = "+";
		this.el_btn_add_object.addEventListener('click', function(e){
			this_ref.addObject();
			this_ref.export();
		});

		// layer name
		function ev_nameChange(e) {
			if (this_ref.curr_layer) {
				if (e.target.value == '')
					e.target.value = this_ref.curr_layer.name;
				else {
					var old_name = this_ref.curr_layer.name;
					var new_name = e.target.value;

					this_ref.curr_layer.name = e.target.value;
					this_ref.refreshLayerList(old_name, new_name);
					this_ref.export();
				}
			}
		}
		this.el_layer_name.addEventListener('keypress', ev_nameChange);
		this.el_layer_name.addEventListener('paste', ev_nameChange);
		this.el_layer_name.addEventListener('input', ev_nameChange);

		this.el_layer_name.addEventListener('click', function(e){
			this.select();
		});
		// layer selection
		this.el_sel_layer.addEventListener('change', function(e){
			this_ref.setLayer(e.target.value);
		});

		// add layer button
		this.el_btn_add_layer.title = "add layer";
		this.el_btn_add_layer.innerHTML = "+";
		this.el_btn_add_layer.addEventListener('click', function(e){
			this_ref.addLayer();
			this_ref.export();
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
			this_ref.export();
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
			this_ref.export();
		});

		// LAYER
		this.el_snap_container.appendChild(this.el_snap_label);
		this.el_snap_container.appendChild(this.el_snap_x);
		this.el_snap_container.appendChild(this.el_snap_sep);
		this.el_snap_container.appendChild(this.el_snap_y);

		this.el_layer_container.appendChild(this.el_layer_name);
		this.el_layer_container.appendChild(this.el_sel_layer);
		this.el_layer_container.appendChild(this.el_btn_add_layer);
		this.el_layer_container.appendChild(this.el_snap_container);

		// OBJECT
		this.el_object_container.appendChild(this.el_input_letter);
		this.el_object_container.appendChild(this.el_sel_letter);
		this.el_object_container.appendChild(this.el_btn_add_object);
		this.el_object_container.appendChild(this.el_input_name);
		this.el_object_container.appendChild(this.el_color_object);

		// IMAGE
		this.el_image_container.appendChild(this.el_image_info);
		this.el_image_container.appendChild(this.el_image_form.container);
		this.el_image_tiles_container.appendChild(this.el_image_preview);
		this.el_image_tiles_container.appendChild(this.el_image_grid);
		this.el_image_container.appendChild(this.el_image_tiles_container);

		this.el_sidebar.appendChild(this.el_layer_container);
		this.el_sidebar.appendChild(this.el_sel_placetype);
		this.el_sidebar.appendChild(this.el_object_container);
		this.el_sidebar.appendChild(this.el_image_container);

		this.appendChild(this.el_sidebar);

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

			// CTRL
			if (keyCode == 17) {
				this_ref.snap_on = true;
			}
		});
		this.container.getContent().addEventListener('mouseenter', function(e){
			this_ref.can_drag = true;
		});
		this.container.getContent().addEventListener('mouseout', function(e){
			if (!this_ref.dragging) this_ref.can_drag = false;
		});
		// 
		document.addEventListener('mousedown', function(e){
			let x = this_ref.pixi.renderer.plugins.interaction.mouse.global.x;
			let y = this_ref.pixi.renderer.plugins.interaction.mouse.global.y;
			let btn = e.button;
			let alt = e.altKey; // e.originalEvent.altKey;

			// dragging canvas
			if (((btn == 1) || (btn == 0 && alt)) && !this_ref.dragging) {
				this_ref.can_drag = true;
				dragStart();
			}
		});

		this.pixi.stage.pointerdown = function(e){
			let x = e.data.global.x;
			let y = e.data.global.y;
			let btn = e.data.originalEvent.button;
			let alt = e.data.originalEvent.altKey; 

			if (!alt) {
				// placing object
				if (btn == 0) {
					if(this_ref.obj_type == 'object') this_ref.placeObject(x - this_ref.camera[0], y - this_ref.camera[1]);
					if(this_ref.obj_type == 'image') this_ref.placeImage(x - this_ref.camera[0], y - this_ref.camera[1]);
				}

				// removing object
				if (btn == 2) {
					if (this_ref.obj_type == 'image' && this_ref.curr_image) {
			        	let x = e.data.global.x;
			        	let y = e.data.global.y;
			        	x -= x % this_ref.curr_layer.snap[0];
			        	y -= y % this_ref.curr_layer.snap[1];

			        	let text_key = Math.floor(x).toString()+','+Math.floor(y).toString()+'.'+this_ref.curr_layer.uuid;
		
						if (this_ref.curr_image.pixi_images[text_key]) {
							delete this_ref.curr_image.pixi_images[text_key];
							this_ref.redrawTiles();

							this_ref.export();
						}
					}
				}

			}

		};

		document.addEventListener('mouseup', function(e) {
			if (e.button == 1 || (e.button == 0 && this_ref.dragging)) {
				dragStop();
			}

			if (e.button == 0) {
				this_ref.export();
			}
		});
		this.pixi.stage.pointermove = function(e) {
			if (this_ref.dragging) {
				this_ref.camera = [
					this_ref.camera_start[0] + (e.data.global.x - this_ref.mouse_start.x) ,
					this_ref.camera_start[1] + (e.data.global.y - this_ref.mouse_start.y) 
				];
				// move grid
				this_ref.grid_container.x = this_ref.camera[0] % this_ref.curr_layer.snap[0];
				this_ref.grid_container.y = this_ref.camera[1] % this_ref.curr_layer.snap[1];

				this_ref.refreshCamera();
			}
		}
		// moving camera with arrow keys
		document.addEventListener('keydown', function(e){
			var keyCode = e.keyCode || e.which;

			let vx = 0;
			let vy = 0;
			// left
			if (keyCode == 37) vx = this_ref.curr_layer.snap[0];
			// right
			if (keyCode == 39) vx = -this_ref.curr_layer.snap[0];
			// up
			if (keyCode == 38) vy = this_ref.curr_layer.snap[1];
			// down
			if (keyCode == 40) vy = -this_ref.curr_layer.snap[1];

			this_ref.camera[0] += vx;
			this_ref.camera[1] += vy;

			this_ref.refreshCamera();
		});

		this.pixi.stage.addChild(this.overlay_container);
		this.pixi.stage.addChild(this.map_container);
		this.pixi.stage.addChild(this.grid_container);

		this.drawGrid();
		this.refreshObjectType();
		
		// tab click
		this.setOnClick(function(self){
			(new MapEditor(app)).load(self.file);
		}, this);	
	}

	onMenuClick (e) {
		var this_ref = this;
		app.contextMenu(e.x, e.y, [
			{label:'rename', click:function(){this_ref.renameModal()}},
			{label:'delete', click:function(){this_ref.deleteModal()}}
		]);
	}

	rename (old_path, new_name) {
		var this_ref = this;
		nwFS.readFile(nwPATH.dirname(this.file)+"/"+new_name, function(err, data){
			if (err) {
				nwFS.rename(old_path, nwPATH.dirname(this_ref.file)+"/"+new_name);
				this_ref.file = nwPATH.dirname(this_ref.file)+"/"+new_name;
				this_ref.setTitle(nwPATH.basename(this_ref.file));
			}
		});
	}

	renameModal () {
		var this_ref = this;
		var filename = this.file;
		blanke.showModal(
			"<label>new name: </label>"+
			"<input class='ui-input' id='new-file-name' style='width:100px;' value='"+nwPATH.basename(filename, nwPATH.extname(filename))+"'/>",
		{
			"yes": function() { this_ref.rename(filename, app.getElement('#new-file-name').value+".map"); },
			"no": function() {}
		});
	}

	delete () {
		nwFS.unlink(this.file);
		this.deleted = true;
		this.close();
	}

	deleteModal () {
		var this_ref = this;
		blanke.showModal(
			"delete \'"+nwPATH.basename(this.file)+"\'",
		{
			"yes": function() { this_ref.delete(); },
			"no": function() {}
		});
	}

	drawGrid () {	
		if (this.curr_layer) {
			var snapx = this.curr_layer.snap[0];
			var snapy = this.curr_layer.snap[1];
			var stage_width =  800; //this.width;
			var stage_height = 600; //this.height;

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
	}

	refreshCamera () {
		this.map_container.setTransform(this.camera[0], this.camera[1]);
		this.drawOrigin();
	}

	drawOrigin () {
		if (this.curr_layer) {
			var snapx = this.curr_layer.snap[0];
			var snapy = this.curr_layer.snap[1];
			var stage_width =  800; //this.width;
			var stage_height = 600; //this.height;

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
	}

	// when object place type selector is changed
	refreshObjectType () {
		this.obj_type = this.el_sel_placetype.value;
		this.el_image_container.classList.add('hidden');
		this.el_object_container.classList.add('hidden');		
		
		if (this.obj_type == 'image') {
			this.el_image_container.classList.remove('hidden');
		}
		if (this.obj_type == 'object') {
			this.el_object_container.classList.remove('hidden');
		}
	}

	// refreshes combo box
	refreshLayerList (old_name, new_name) {
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

		// rename layer in objects
		if (old_name && new_name) {		
			for (var o = 0; o < this.objects.length; o++) {
				for (let t in this.objects[o].pixi_texts) {
					var text = this.objects[o].pixi_texts[t];
					if (text && text.layer_name == old_name) 
						text.layer_name = new_name
				}
			}
		}
	}

	// refreshes object combo box 
	refreshObjectList (obj_type='image') {
		app.clearElement(this.el_sel_object);
		var placeholder = app.createElement("option");
		placeholder.selected = true;
		placeholder.disabled = true;
		this.el_sel_object.appendChild(placeholder);

		for (var o = 0; o < this.objects.length; o++) {
			var new_option = app.createElement("option");
			new_option.value = this.objects[o].name;
			new_option.innerHTML = this.objects[o].name;
			this.el_sel_letter.appendChild(new_option);
		}
	}

	// add all images in project to the search bar
	refreshImageList() {
		var this_ref = this;
		app.removeSearchGroup('scene_image');
		nwKLAW(nwPATH.join(app.project_path,'assets'))
			.on('data', function(item){
				var img_path = nwPATH.relative(app.project_path,item.path).replace(/assets[/\\]/,'');
				app.addSearchKey({key: img_path, group: 'scene_image', tags: ['image'], onSelect: function() {
					this_ref.setImage(item.path);
				}});
			});
	}

	refreshImageSelectionList() {
		this.selected_xmin = -1;
		this.selected_ymin = -1;
		this.selected_image_frames = [];

		var el_image_frames = document.querySelectorAll('.image-grid > .cell.selected');
		if (el_image_frames) {
			for (var frame of el_image_frames) {
				let x = parseInt(frame.style.left);
				let y = parseInt(frame.style.top);

				this.selected_image_frames.push({
					'x':x,
					'y':y,
					'width':parseInt(frame.style.width),
					'height':parseInt(frame.style.height)
				})

				if (this.selected_xmin == -1 || x < this.selected_xmin) this.selected_xmin = x;
				if (this.selected_ymin == -1 || y < this.selected_ymin) this.selected_ymin = y;
			}
		}
	}

	refreshImageGrid() {
		if (this.curr_image) {
			var img_width = parseInt(this.el_image_preview.width);
			var img_height = parseInt(this.el_image_preview.height);
			var grid_w = this.curr_image.snap[0];
			var grid_h = this.curr_image.snap[1];
			
			var str_table = "";
			if (grid_w > 2 && grid_h > 2) {
				let rows = Math.ceil(img_height / grid_h) * (this.curr_image.spacing[1] > 0 ? this.curr_image.spacing[1] : 1);
				let columns = Math.ceil(img_width / grid_w) * (this.curr_image.spacing[0] > 0 ? this.curr_image.spacing[0] : 1);

				for (var gy = 0; gy < rows; gy += 1) {
					let y = (gy * this.curr_image.spacing[1]) + (gy * grid_h) + this.curr_image.offset[1];
					for (var gx = 0; gx < columns; gx += 1) {
						let x = (gx * this.curr_image.spacing[0]) + (gx * grid_w) + this.curr_image.offset[0];
						str_table += "<div class='cell' style='top:"+y+"px;left:"+x+"px;width:"+grid_w+"px;height:"+grid_h+"px'></div>";
					}
				}
			}
			this.el_image_grid.innerHTML = str_table;
			this.el_image_grid.style.width = (Math.ceil(img_width / grid_w) * grid_w) + "px";
			this.el_image_grid.style.height = (Math.ceil(img_height / grid_h) * grid_h) + "px";

			this.export();
		}
	}

	placeObject (x, y, from_load_snapped) {
		var this_ref = this;
		var curr_object = this.curr_object;

		if (curr_object && this.curr_layer) {
			var new_graph = new PIXI.Graphics();
			new_graph.beginFill(parseInt(this.curr_object.color.replace('#',"0x"),16), .5);

			let snapx = this.curr_layer.snap[0] / 2;
			let snapy = this.curr_layer.snap[1] / 2;

			new_graph.snapped = false;
			if (from_load_snapped == null) {
				if (x < 0) x -= snapx;
				if (y < 0) y -= snapy;
			}
			if (from_load_snapped || (this.snap_on && from_load_snapped == null)) {
				x -= x % snapx;
				y -= y % snapy;
				new_graph.snapped = true;
			}

			let radius = 16;

			new_graph.drawCircle(x, y, radius);
			new_graph.place_x = x;
			new_graph.place_y = y;
			new_graph.label = new PIXI.Text(curr_object.char,{
				fontFamily: 'ProggySquare', 
				fill: curr_object.color,
				align: 'center',
				fontSize: radius*1.5
			});
			new_graph.radius = radius;
			new_graph.label.x = x - (new_graph.label.width/2);
			new_graph.label.y = y - (new_graph.label.height/2);

			var text_key = Math.floor(x).toString()+','+Math.floor(y).toString()+'.'+this.curr_layer.uuid;
			if (curr_object.pixi_texts[text_key]) curr_object.pixi_texts[text_key].destroy();
			
			new_graph.place_x = x;
			new_graph.place_y = y;

			new_graph.grid_x = Math.floor(x / snapx);
			new_graph.grid_y = Math.floor(y / snapy);

			new_graph.uuid = curr_object.uuid;
			new_graph.text_key = text_key;
			new_graph.layer_name = this.curr_layer.name;
			new_graph.layer_uuid = this.curr_layer.uuid;

			new_graph.interactive = true;
			new_graph.on('rightdown', function(e){
				if (this_ref.obj_type == 'object' && e.target.layer_uuid === this_ref.curr_layer.uuid && this_ref.curr_object.pixi_texts[e.target.text_key]) {
					this_ref.curr_object.pixi_texts[e.target.text_key].label.destroy();
					this_ref.curr_object.pixi_texts[e.target.text_key].destroy();
					this_ref.curr_object.pixi_texts[e.target.text_key] = null;

					this_ref.export();
				}
			});
			
			curr_object.pixi_texts[text_key] = new_graph;
			this.curr_layer.container.addChild(new_graph);
			this.curr_layer.container.addChild(new_graph.label);
		}
	}

	placeImageFrame (x, y, frame, from_load_snapped) {
		let curr_image = this.curr_image;
		if (from_load_snapped != null)
			curr_image = from_load_snapped;

		let new_tile_texture = new PIXI.Texture(
            curr_image.pixi_resource.texture,
            new PIXI.Rectangle(frame.x, frame.y, frame.width, frame.height)
        );
        new_tile_texture.layer_uuid = this.curr_layer.uuid;

        if (!new_tile_texture) return;

		let new_tile = {'x':0,'y':0,'w':0,'h':0,'snapped':false};

		if (from_load_snapped == null) {
			x += (frame.x - this.selected_xmin);
			y += (frame.y - this.selected_ymin);
		}

		let text_key = Math.floor(x - (x % this.curr_layer.snap[0])).toString()+','+Math.floor(y - (y % this.curr_layer.snap[1])).toString()+'.'+this.curr_layer.uuid;

		if (from_load_snapped == null) {
			if (x < 0) x -= this.curr_layer.snap[0];
			if (y < 0) y -= this.curr_layer.snap[1];
		}
		if (from_load_snapped || (this.snap_on && from_load_snapped == null)) {
			x -= x % this.curr_layer.snap[0];
			y -= y % this.curr_layer.snap[1];
			new_tile.snapped = true;
		}

		// add if a tile isn't already there
		if (!curr_image.pixi_images[text_key]) {
			if (!curr_image.pixi_tilemap[this.curr_layer.uuid]) {
				curr_image.pixi_tilemap[this.curr_layer.uuid] = new PIXI.tilemap.CompositeRectTileLayer(0, curr_image.pixi_resource.texture);
				this.curr_layer.container.addChild(curr_image.pixi_tilemap[this.curr_layer.uuid]);
			}
			curr_image.pixi_tilemap[this.curr_layer.uuid].addFrame(new_tile_texture,x,y);
			new_tile.x = x;
			new_tile.y = y;
			new_tile.frame = frame;
			new_tile.texture = new_tile_texture;

			new_tile.uuid = curr_image.uuid;
			new_tile.text_key = text_key;
			new_tile.layer_name = this.curr_layer.name;
			new_tile.layer_uuid = this.curr_layer.uuid;
			curr_image.pixi_images[text_key] = new_tile;
		}
	}

	placeImage (x, y, from_load_snapped) {
		if (this.curr_image && this.curr_layer) {
			for (var frame of this.selected_image_frames) {
				this.placeImageFrame(x, y, frame, from_load_snapped);
			}
		}
	}

	// uses curr_image and curr_layer
	redrawTiles () {
		if (!this.curr_image) return;

		// redraw all tiles 
		for (var layer_name in this.curr_image.pixi_tilemap) {
			this.curr_image.pixi_tilemap[layer_name].clear();
			for (var t in this.curr_image.pixi_images) {
				let tile = this.curr_image.pixi_images[t];
				this.curr_image.pixi_tilemap[layer_name].addFrame(tile.texture,tile.x,tile.y);
			}
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
			uuid: guid()
		}

		info.pixi_texts = {};
		this.objects.push(info);
		this.setObject(info.name);
	}

	updateGlobalObjList() {
		global_objects = [];
		for (var o = 0; o < this.objects.length; o++) {
			global_objects.push({
				name: this.objects[o].name,
				char: this.objects[o].char,
				color: this.objects[o].color
			});
		}
	}

	setObject (name) {
		for (var l = 0; l < this.objects.length; l++) {
			if (this.objects[l].name === name) {
				this.curr_object = this.objects[l];
				this.el_input_letter.value = this.curr_object.char;
				this.el_input_name.value = this.curr_object.name;
				this.el_color_object.value = this.curr_object.color;
				return;
			}
		}	
	}

	setImage (path, onReady) {
		// set current image variable
		var img_found = false;
		for (var img of this.images) {
			if (img.path == path) {
				img_found = true;
				this.curr_image = img;

				var this_ref = this;
				var loader = new PIXI.loaders.Loader();
				loader.add(path);
				loader.load(function(loader, resources){
					// save texture info
					if (!img.pixi_resource) {
						img.pixi_resource = resources[img.path];
					} 

					// update image info text
					this_ref.el_image_info.innerHTML = this_ref.getImageRelPath(img.path) + "<br/>" + img.pixi_resource.texture.width + " x " +  img.pixi_resource.texture.height;
					this_ref.el_image_info.title = this_ref.getImageRelPath(img.path);

					this_ref.el_image_preview.onload = function(){
						this_ref.refreshImageGrid();		
					}
					this_ref.el_image_preview.src = img.path;
					if (onReady) onReady(img);
	            });

				// set image inputs
				for (var property of ['snap', 'offset', 'snap']) {
					this.el_image_form.setValue(property, this.curr_image[property][0], 0);
					this.el_image_form.setValue(property, this.curr_image[property][1], 1);
				}
			}
		}
		// add image to scene library
		if (!img_found) {
			this.images.push({
				path: path,
				snap: this.curr_layer.snap.slice(0),
				offset: [0,0],
				spacing: [0,0],
				uuid: guid(),
				pixi_images: {},
				pixi_tilemap: {}
			});
			this.export();
			this.setImage(path);
		}
	}

	getImageRelPath (path) {
		return nwPATH.relative(app.project_path,path);
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

		info.snap = info.snap.map(Number);

		info.container = new PIXI.Container();
		this.map_container.addChild(info.container);
		this.layers.push(info);
		this.setLayer(info.name);

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

	load (file_path) {
		this.file = file_path;
		var data = nwFS.readFileSync(file_path, 'utf-8');
		var first_layer = null;

		if (data.length > 5) {
			data = JSON.parse(data);

			// layers
			for (var l = 0; l < data.layers.length; l++) {
				this.addLayer(data.layers[l]);
			}

			// objects
			for (var o = 0; o < data.objects.length; o++) {
				var obj = data.objects[o];
				this.addObject(obj);

				for (var layer_name in obj.coords) {
					this.setLayer(layer_name);
					for (var c = 0; c < obj.coords[layer_name].length; c++) {
						this.placeObject(obj.coords[layer_name][c][0], obj.coords[layer_name][c][1], obj.coords[layer_name][c][2]);
					}
				}
			}

			// images
			let this_ref = this;
			data.images.forEach(function(img, i){
				var full_path = nwPATH.resolve(app.project_path,img.path);
				this_ref.images.push({
					path: full_path,
					snap: img.snap,
					offset: img.offset,
					spacing: img.spacing,
					uuid: img.uuid,
					pixi_images: {},
					pixi_tilemap: {}
				});
				this_ref.setImage(full_path, function(img_ref){
					for (var layer_name in img.coords) {
						this_ref.setLayer(layer_name);
						for (var coord of img.coords[layer_name]) {
							this_ref.placeImageFrame(coord[0], coord[1], {
								'x':coord[2], 'y':coord[3], 'width':coord[4], 'height':coord[5]
							}, img_ref)
						}
					}

				});				
			});

			if (data.objects.length > 0) 
				this.updateGlobalObjList();

			this.refreshObjectList();
		}

		this.setTitle(nwPATH.basename(file_path));
	}

	export () {
		if (this.deleted) return;

		let export_data = {'objects':[], 'layers':[], 'images':[]};
		let layer_names = {};

		// layers
		for (let l = 0; l < this.layers.length; l++) {
			let layer = this.layers[l];
			export_data.layers.push({
				name: layer.name,
				depth: layer.depth,
				offset: layer.offset,
				snap: layer.snap,
				uuid: layer.uuid
			})
			layer_names[layer.name] = true;
		}

		// objects
		for (let o = 0; o < this.objects.length; o++) {
			let obj = this.objects[o];
			let exp_obj = {
				name: obj.name,
				char: obj.char,
				color: obj.color,
				uuid: obj.uuid,
				coords: {}
			}
			for (let t in obj.pixi_texts) { 
				if (obj.pixi_texts[t] && layer_names[obj.pixi_texts[t].layer_name]) {
					if (!exp_obj.coords[obj.pixi_texts[t].layer_name])
						exp_obj.coords[obj.pixi_texts[t].layer_name] = [];

					let new_obj = [obj.pixi_texts[t].place_x, obj.pixi_texts[t].place_y];
					if (obj.pixi_texts[t].shape == 'circle') 
						new_obj.push({'shape':'circle','radius':obj.pixi_texts[t].radius});
					
					exp_obj.coords[obj.pixi_texts[t].layer_name].push(new_obj);
				}
			}
			export_data.objects.push(exp_obj);
		}

		//images
		for (let obj of this.images) {
			let exp_img = {
				path: nwPATH.relative(app.project_path,obj.path),
				snap: obj.snap,
				offset: obj.offset,
				spacing: obj.spacing,
				uuid: obj.uuid,
				coords: {}
			}

			for (let i in obj.pixi_images) { 
				let img = obj.pixi_images[i];
				if (img && layer_names[img.layer_name]) {

					if (!exp_img.coords[img.layer_name])
						exp_img.coords[img.layer_name] = [];

					exp_img.coords[img.layer_name].push([
						img.x, img.y,
						img.frame.x, img.frame.y, img.frame.width, img.frame.height,
						img.snapped
					]);
				}
			}
			export_data.images.push(exp_img);
		}


		nwFS.writeFileSync(this.file, JSON.stringify(export_data));
	}
}

document.addEventListener('fileChange', function(e){
	if (e.detail.type == 'change') {
		app.removeSearchGroup("Map");
		addScenes(app.project_path);
	}
});

function addScenes(folder_path) {
	nwFS.readdir(folder_path, function(err, files) {
		if (err) return;
		files.forEach(function(file){
			var full_path = nwPATH.join(folder_path, file);
			nwFS.stat(full_path, function(err, file_stat){		
				// iterate through directory			
				if (file_stat.isDirectory())
					addScenes(full_path);

				// add file to search pool
				else if (file.endsWith('.scene')) {
					app.addSearchKey({
						key: file,
						onSelect: function(file_path){
							if (!Tab.focusTab(nwPATH.basename(file_path)))
								(new SceneEditor(app)).load(file_path);
						},
						tags: ['scene'],
						args: [full_path],
						group: 'Scene'
					});
				}
			});
		});
	});
}

document.addEventListener("openProject", function(e){
	var proj_path = e.detail.path;
	app.removeSearchGroup("Scene");
	addScenes(proj_path);

	app.addSearchKey({
		key: 'Create scene',
		onSelect: function() {
			var map_dir = nwPATH.join(app.project_path,'scenes');
			// overwrite the file if it exists. fuk it (again)!!
			nwFS.mkdir(map_dir, function(err){
				nwFS.readdir(map_dir, function(err, files){
					nwFS.writeFile(nwPATH.join(map_dir, 'scene'+files.length+'.scene'),"");
				
					// edit the new script
					var new_scene_editor = new SceneEditor(app)
					// add some premade objects from previous map
					new_scene_editor.load(nwPATH.join(map_dir, 'scene'+files.length+'.scene'));
					for (var o = 0; o < global_objects.length; o++) {
						new_scene_editor.addObject(global_objects[o]);
					}
					new_scene_editor.addLayer();
					new_scene_editor.refreshObjectList();
				});
			});	
		},
		tags: ['new']
	});
});