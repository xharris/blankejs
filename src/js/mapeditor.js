var global_objects = [];

class MapEditor extends Editor {
	constructor (...args) {
		super(...args);
		this.setupTab();

		var this_ref = this;

		this.file = '';
		this.map_folder = '/maps';
		
		this.grid_opacity = 0.1;
		this.snap_on = true;
		this.deleted = false;

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
					obj.style.fill = this_ref.curr_object.color;
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
		this.container.getContent().addEventListener('mousedown', function(e){
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

			// placing object
			if (btn == 0 && !alt) {
				this_ref.placeObject(x - this_ref.camera[0], y - this_ref.camera[1]);
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

		this.drawGrid();
		
		// tab click
		this.setOnClick(function(self){
			(new MapEditor(app)).load(self.file);
		}, this);	}

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

	placeObject (x, y, from_load_snapped) {
		var this_ref = this;
		var curr_object = this.curr_object;

		if (curr_object && this.curr_layer) {
			var new_text = new PIXI.Text(curr_object.char,{
				fontFamily: 'ProggySquare', 
				fill: curr_object.color,
				align: 'center',
				fontSize: this.curr_layer.snap[1]
			});

			new_text.snapped = false;
			if (from_load_snapped == null) {
				if (x < 0) x -= this.curr_layer.snap[0];
				if (y < 0) y -= this.curr_layer.snap[1];
			}
			if (from_load_snapped || (this.snap_on && from_load_snapped == null)) {
				x -= x % this.curr_layer.snap[0];
				y -= y % this.curr_layer.snap[1];
				new_text.snapped = true;
			}

			var text_key = Math.floor(x).toString()+','+Math.floor(y).toString()+'.'+this.curr_layer.uuid;
			if (curr_object.pixi_texts[text_key]) curr_object.pixi_texts[text_key].destroy();
			
			new_text.place_x = x;
			new_text.place_y = y;

			new_text.grid_x = Math.floor(x / this.curr_layer.snap[0]);
			new_text.grid_y = Math.floor(y / this.curr_layer.snap[1]);

			new_text.x += x + (this.curr_layer.snap[0]/2) - (new_text.width/2);
			new_text.y += y + (this.curr_layer.snap[1]/2) - (new_text.height/2);
			new_text.uuid = curr_object.uuid;
			new_text.text_key = text_key;
			new_text.layer_name = this.curr_layer.name;
			new_text.layer_uuid = this.curr_layer.uuid;

			new_text.interactive = true;
			new_text.on('rightdown', function(e){
				if (e.target.layer_uuid === this_ref.curr_layer.uuid && this_ref.curr_object.pixi_texts[e.target.text_key]) {
					this_ref.curr_object.pixi_texts[e.target.text_key].destroy();
					this_ref.curr_object.pixi_texts[e.target.text_key] = null;

					this_ref.export();
				}
			});
			
			var new_graph = new PIXI.Graphics();
			new_graph.beginFill(this.curr_object.color, 0);
			new_graph.drawRect(-((this.curr_layer.snap[0]/2) - (new_text.width/2)), -((this.curr_layer.snap[1]/2) - (new_text.height/2)), this.curr_layer.snap[0], this.curr_layer.snap[1]);
			new_text.addChild(new_graph);
			
			curr_object.pixi_texts[text_key] = new_text;
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
					this.setLayer(layer_name)
					for (var c = 0; c < obj.coords[layer_name].length; c++) {
						this.placeObject(obj.coords[layer_name][c][0], obj.coords[layer_name][c][1], obj.coords[layer_name][c][2]);
					}
				}
			}

			if (data.objects.length > 0) 
				this.updateGlobalObjList();

			this.refreshObjectList();
		}

		this.setTitle(nwPATH.basename(file_path));
	}

	export () {
		if (this.deleted) return;

		let export_data = {'objects':[], 'layers':[]};
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
					exp_obj.coords[obj.pixi_texts[t].layer_name].push([
						obj.pixi_texts[t].place_x,
						obj.pixi_texts[t].place_y,
						obj.pixi_texts[t].snapped
					]);
				}
			}
			export_data.objects.push(exp_obj);
		}


		nwFS.writeFileSync(this.file, JSON.stringify(export_data));
	}
}

document.addEventListener('fileChange', function(e){
	if (e.detail.type == 'change') {
		app.removeSearchGroup("Map");
		addMaps(app.project_path);
	}
});

function addMaps(folder_path) {
	nwFS.readdir(folder_path, function(err, files) {
		if (err) return;
		files.forEach(function(file){
			var full_path = nwPATH.join(folder_path, file);
			nwFS.stat(full_path, function(err, file_stat){		
				// iterate through directory			
				if (file_stat.isDirectory())
					addMaps(full_path);

				// add file to search pool
				else if (file.endsWith('.map')) {
					app.addSearchKey({
						key: file,
						onSelect: function(file_path){
							if (!Tab.focus(nwPATH.basename(file_path)))
								(new MapEditor(app)).load(file_path);
						},
						tags: ['map'],
						args: [full_path],
						group: 'Map'
					});
				}
			});
		});
	});
}

document.addEventListener("closeProject", function(e){	
	app.removeSearchGroup("Map");
});

document.addEventListener("openProject", function(e){
	var proj_path = e.detail.path;
	app.removeSearchGroup("Map");
	addMaps(proj_path);

	app.addSearchKey({
		key: 'Add a map',
		onSelect: function() {
			var map_dir = nwPATH.join(app.project_path,'maps');
			// overwrite the file if it exists. fuk it (again)!!
			nwFS.mkdir(map_dir, function(err){
				nwFS.readdir(map_dir, function(err, files){
					nwFS.writeFile(nwPATH.join(map_dir, 'map'+files.length+'.map'),"");
				
					// edit the new script
					var new_map_editor = new MapEditor(app)
					// add some premade objects from previous map
					new_map_editor.load(nwPATH.join(map_dir, 'map'+files.length+'.map'));
					for (var o = 0; o < global_objects.length; o++) {
						new_map_editor.addObject(global_objects[o]);
					}
					new_map_editor.addLayer();
					new_map_editor.refreshObjectList();
				});
			});	
		},
		tags: ['new']
	});
});