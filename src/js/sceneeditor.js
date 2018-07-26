var earcut = require('./includes/earcut.js');
var global_objects = [];

// http://www.html5gamedevs.com/topic/7507-how-to-move-the-sprite-to-the-top/?do=findComment&comment=45162
function bringToFront(sprite, parent) {var sprite = (typeof(sprite) != "undefined") ? sprite.target || sprite : this;var parent = parent || sprite.parent || {"children": false};if (parent.children) {    for (var keyIndex in sprite.parent.children) {         if (sprite.parent.children[keyIndex] === sprite) {            sprite.parent.children.splice(keyIndex, 1);            break;        }    }    parent.children.push(sprite);}}
function sendToBack(sprite, parent) {var sprite = (typeof(sprite) != "undefined") ? sprite.target || sprite : this;var parent = parent || sprite.parent || {"children": false};if (parent.children) {    for (var keyIndex in sprite.parent.children) {          if (sprite.parent.children[keyIndex] === sprite) {            sprite.parent.children.splice(keyIndex, 1);            break;        }    }    parent.children.splice(0,0,sprite);    }}

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

		this.placing_object = false;
		this.dot_preview = null;
		this.image_preview = null;

		this.can_drag = false;
		this.dragging = false;
		this.mouse_start = [0,0];
		this.camera_start = [0,0];
		this.camera = [0,0];
		this.mouse = [0,0];
		this.game_width = window.innerWidth;
		this.game_height = window.innerHeight;

		this.pixi = new PIXI.Application(this.game_width, this.game_height, {
			backgroundColor: 0x424242,
			antialias: false,
			autoResize: true,
		});
		this.grid_color = 0xBDBDBD;
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
		this.coord_text_style = new PIXI.TextStyle({
			fontSize: 12,
			fill: 'white',
			stroke: 'black',
			strokeThickness: 2,
			fontFamily: 'ProggySquare',
			fontWeight: '100'
		});
		this.coord_text_x = new PIXI.Text('x=0', this.coord_text_style);
		this.coord_text_y = new PIXI.Text('y=0', this.coord_text_style);

		this.grid_container.addChild(this.origin_graphics);
		this.grid_container.addChild(this.coord_text_x);
		this.grid_container.addChild(this.coord_text_y);

		this.grid_container.addChild(this.grid_graphics);
		this.overlay_container.addChild(this.origin_graphics);

		var el_br = app.createElement("br");

		// create sidebar
		this.el_sidebar 		= app.createElement("div","sidebar");

		// IMAGE elements
		this.el_image_form = new BlankeForm([
			['snap', 'number', {'inputs':2, 'separator':'x'}],
			['offset', 'number', {'inputs':2, 'separator':'x'}],
			['spacing', 'number', {'inputs':2, 'separator':'x'}],
			['align', 'select', {'choices':['top-left','top-right','bottom-left','bottom-right']}]
		]);
		this.el_image_info 		= app.createElement("p","image-info");
		this.el_image_container	= app.createElement("div","image-container");
		this.el_image_tiles_container = app.createElement("div","image-tiles-container")
		this.el_image_preview	= app.createElement("img","image-preview");
		this.el_image_grid		= app.createElement("div","image-grid");

		this.el_image_container.classList.add('hidden');

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
		this.el_snap_container	= app.createElement("div","snap-container");
		this.el_snap_label		= app.createElement("p","snap-label");
		this.el_snap_x			= app.createElement("input","snap-x");
		this.el_snap_y			= app.createElement("input","snap-y");
		this.el_snap_sep		= app.createElement("p","snap-sep");

		this.el_sel_placetype 	= app.createElement("select","select-placetype");
		this.el_sel_object		= app.createElement("select","select-object");
		this.el_input_object	= app.createElement("input","input-object");
		// add object types
		let obj_types = ['image','object'];
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
				if (isNaN(snapx) || isNaN(snapy <= 0))
					return this_ref.curr_image.snap.slice();

				if (snapx < 0) snapx = 0;
				if (snapy < 0) snapy = 0;
				this_ref.curr_image.snap[0] = snapx;
				this_ref.curr_image.snap[1] = snapy;

				this_ref.refreshImageGrid();
			}
		});

		this.el_image_form.setValue('offset', 0, 0);
		this.el_image_form.setValue('offset', 0, 1);
		this.el_image_form.onChange('offset', function(value){
			let offsetx = value[0];
			let offsety = value[1];

			if (this_ref.curr_image) {
				if (isNaN(offsetx) || isNaN(offsety))
					return this_ref.curr_image.offset.slice();

				this_ref.curr_image.offset[0] = offsetx;
				this_ref.curr_image.offset[1] = offsety;

				this_ref.refreshImageGrid();

			}
		});

		this.el_image_form.setValue('spacing', 0, 0);
		this.el_image_form.setValue('spacing', 0, 1);
		this.el_image_form.onChange('spacing', function(value){
			let spacingx = value[0];
			let spacingy = value[1];

			if (this_ref.curr_image) {
				if (spacingx < 0 || spacingy < 0)
					return this_ref.curr_image.spacing.slice();

				this_ref.curr_image.spacing[0] = spacingx;
				this_ref.curr_image.spacing[1] = spacingy;

				this_ref.refreshImageGrid();
			}
		});

		this.el_image_form.onChange('align', function(value){
			if (this_ref.curr_image) {
				this_ref.curr_image.align = value[0];
			}
		});

		this.el_image_grid.ondragstart = function() { return false; };
		this.selected_image_frames = [];
		this.selected_xmin = -1;
		this.selected_ymin = -1;
		this.selected_width = -1;
		this.selected_height = -1;
		function selectImageTiles(e) {
			if (e.target && e.target.matches('div.cell') && e.buttons != 0) {
				if (e.buttons == 1) {
					// if SHIFT is not held down, clear all other tiles
					if (!e.shiftKey) {
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
						obj.label.text = this_ref.curr_object.char;
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
					obj.poly.destroy();
					this_ref.placeObject(obj.points);
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

		this.el_layer_form = new BlankeForm([
			['name', 'text'],
			['snap', 'number', {'inputs':2, 'separator':'x'}]
		]);

		this.el_layer_form.setValue('snap', 32, 0);
		this.el_layer_form.setValue('snap', 32, 1);
		this.el_layer_form.onChange('snap', function(value){
			var new_x = parseInt(value[0]);
			var new_y = parseInt(value[1]);
			if (new_x <= 0) new_x = this_ref.curr_layer.snap[0];
			this_ref.curr_layer.snap[0] = new_x;
			if (new_y <= 0) new_y = this_ref.curr_layer.snap[1];
			this_ref.curr_layer.snap[1] = new_y;

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

		this.el_layer_form.onChange('name', function(value){
			value = value[0];

			if (this_ref.curr_layer) {
				if (value == '')
					return [this_ref.curr_layer.name];
				else {
					var old_name = this_ref.curr_layer.name;
					var new_name = value;

					this_ref.curr_layer.name = value;
					this_ref.refreshLayerList(old_name, new_name);
					this_ref.export();
				}
			}
		});

		this.el_layer_control = new BlankeListView({
			title:'layers',
			buttons:['add'],
			new_item:'layer',
			actions:{
				"delete":"remove layer"
			}
		});
		this.el_layer_control.onItemAction = function(icon, text) {
			if (icon == "delete") {
				this_ref.el_layer_control.removeItem(text);
			}
		}
		this.el_layer_control.onItemSelect = function(text) {
			this_ref.setLayer(text);
		}
		this.el_layer_control.onItemAdd = function(text) {
			let layer_name = this_ref.addLayer();
			this_ref.export();
			return layer_name;
		}

		// LAYER
		this.el_layer_container.appendChild(this.el_layer_control.container);
		this.el_layer_container.appendChild(this.el_layer_form.container);

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

			// nothing atm
		});
		window.addEventListener('keyup', function(e){
			var keyCode = e.keyCode || e.which;

			// CTRL
			if (keyCode == 17) {
				this_ref.snap_on = true;
			}

			// ENTER
			if (keyCode == 13) {
				if (this_ref.obj_type == "object" && this_ref.placing_object) {
					this_ref.placeObject(this_ref.placing_object.points.slice());
					this_ref.clearPlacingObject();
					this_ref.export();
				}
			}
		});
		this.container.getContent().addEventListener('mouseenter', function(e){
			this_ref.can_drag = true;
		});
		this.container.getContent().addEventListener('mouseout', function(e){
			if (!this_ref.dragging) this_ref.can_drag = false;
		});
		
		this.tile_start = [0,0];
		this.tile_straightedge = new PIXI.Graphics();
		this.map_container.addChild(this.tile_straightedge);

		function deleteTile(x,y) {
			for (let s in this_ref.curr_image.pixi_images) {
                let sprite = this_ref.curr_image.pixi_images[s].sprite;
                let rect = sprite.getBounds();
                rect.x -= this_ref.camera[0];
                rect.y -= this_ref.camera[1];
                if (rect.contains(x,y)) {
                    sprite.destroy();
                    delete this_ref.curr_image.pixi_images[s];
                    this_ref.redrawTiles();

                    this_ref.export();
                }
            }
		}

        this.pointer_down = -1;
		this.pixi.stage.on('pointerdown',function(e){
			
			let x = e.data.global.x;
			let y = e.data.global.y;
			let btn = e.data.originalEvent.button;
			let alt = e.data.originalEvent.altKey;

			this_ref.pointer_down = btn;

			x -= this_ref.camera[0];
			y -= this_ref.camera[1];

			if (x < 0) x -= this_ref.curr_layer.snap[0];
			if (y < 0) y -= this_ref.curr_layer.snap[1];

			// dragging canvas
			if (((btn == 1) || (btn == 0 && alt)) && !this_ref.dragging) {
				this_ref.can_drag = true;
				dragStart();
			}

			if (!alt && !this_ref.dragging) {
				// placing object
				if (btn == 0) {
					if(this_ref.obj_type == 'object') 
						this_ref.placeObjectPoint(x, y);
					
					if(this_ref.obj_type == 'image') {
						/*
						x -= x % this_ref.curr_layer.snap[0];
						y -= y % this_ref.curr_layer.snap[1];
						*/
						this_ref.tile_start = [this_ref.mouse[0], this_ref.mouse[1]];
						bringToFront(this.tile_straightedge)
					}
				}

				// removing object
				if (btn == 2) {
					if (this_ref.obj_type == 'object') {
						this_ref.removeObjectPoint();
					}
					if (this_ref.obj_type == 'image' && this_ref.curr_image) {
                        deleteTile(x,y);
                    }
				}

			}
		});

		this.pixi.stage.on('pointerup',function(e){
			let x = this_ref.mouse[0];
			let y = this_ref.mouse[1];
			let btn = e.data.originalEvent.button;
			let alt = e.data.originalEvent.altKey; 
        	this_ref.pointer_down = -1;

			if (!alt && !this_ref.dragging) {
				if (btn == 0) {
					this_ref.tile_straightedge.clear()

					// place tiles in a snapped line
					if (this_ref.placeImageReady()) {
						let start_x = this_ref.tile_start[0],
						    start_y = this_ref.tile_start[1];
						if (x == this_ref.tile_start[0] && y == this_ref.tile_start[1]) {
							this_ref.placeImage(x, y, this_ref.curr_image);

						} else {
							let ix = start_x,
								iy = start_y,
								target_x = x,
								target_y = y,
								x_incr = this_ref.selected_width,
								y_incr = this_ref.selected_height,
								x_diff = Math.abs(target_x - start_x),
								y_diff = Math.abs(target_y - start_y),
								checkX = false,
								checkY = false;

								if (x_diff > y_diff) 
									y_incr = (target_y - start_y) / (x_diff / x_incr);
								
								if (x_diff < y_diff) 
									x_incr = (target_x - start_x) / (y_diff / y_incr);
								
							do {
								x_diff = (target_x - ix);
								y_diff = (target_y - iy);

								this_ref.placeImage(ix, iy, this_ref.curr_image);

								checkX = (start_x < target_x && ix < target_x) || (start_x > target_x && ix > target_x);
								checkY = (start_y < target_y && iy < target_y) || (start_y > target_y && iy > target_y);

								if (checkX) ix += Math.sign(x_diff)*x_incr;
								if (checkY) iy += Math.sign(y_diff)*y_incr;
							} while (checkX || checkY);
						}
					}
				}
			}
		});

		this.place_mouse = [0,0];
		this.pixi.stage.on('pointermove', function(e) {
			let x = e.data.global.x;
			let y = e.data.global.y;
			let btn = this_ref.pointer_down;
			let alt = e.data.originalEvent.altKey; 

			let snapx = this_ref.curr_layer.snap[0];
			let snapy = this_ref.curr_layer.snap[1];
			
			let mx = x-this_ref.camera[0],
				my = y-this_ref.camera[1];

			if (mx < 0) { mx -= snapx; x -= snapx; }
			if (my < 0) { my -= snapy; y -= snapy; }

			this_ref.place_mouse = [Math.floor(x),Math.floor(y)];
			this_ref.mouse = [Math.floor(mx),Math.floor(my)];

			if (!e.data.originalEvent.ctrlKey) {
				this_ref.place_mouse = [
					x - (mx%snapx),
					y - (my%snapy)
				]
				this_ref.mouse = [
					mx - (mx%snapx),
					my - (my%snapy)
				];
			}
			this_ref.drawCrosshair();

			if (this_ref.dragging) {
				this_ref.setCameraPosition(
					this_ref.camera_start[0] + (e.data.global.x - this_ref.mouse_start.x),
					this_ref.camera_start[1] + (e.data.global.y - this_ref.mouse_start.y) 
				)
			}

			if (!alt && !this_ref.dragging) {
				if (btn == 0) {
					// placing tiles in a snapped line
					if (this_ref.placeImageReady()) {
						this_ref.tile_straightedge.clear()
						this_ref.tile_straightedge.lineStyle(2, 0xBDBDBD)
							.moveTo(this_ref.tile_start[0], this_ref.tile_start[1])
							.lineTo(this_ref.mouse[0], this_ref.mouse[1]);
					}
				}           
			}

			if (btn == 2) {
				if (this_ref.obj_type == 'image' && this_ref.curr_image) {
                    //blanke.cooldownFn("delete_tile",500,function(){
                        deleteTile(mx, my);                                
                    //});
				}
            }

			this_ref.drawDotPreview();
		});
        
		document.addEventListener('mouseup', function(e) {
			if (e.button == 1 || (e.button == 0 && this_ref.dragging)) {
				dragStop();
			}


			if (e.button == 0) {
				this_ref.export();
			}
		});
        
		// moving camera with arrow keys
		document.addEventListener('keydown', function(e){
			if (document.activeElement === document.body) {
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
		}
		});

		this.pixi.stage.addChild(this.overlay_container);
		this.pixi.stage.addChild(this.map_container);
		this.pixi.stage.addChild(this.grid_container);

		this.drawGrid();
		
		// tab click
		this.setOnClick(function(self){
			(new MapEditor(app)).load(self.file);
		}, this);	

		this.obj_type = 'object';
		this.refreshObjectType();

		document.addEventListener('fileChange', function(e){
			if (e.detail.type == 'change') {
				console.log('new',e.detail);
				if (this_ref.curr_image)
					console.log('old',this_ref.curr_image.path);
				this_ref.refreshImageList();
			}
		});

		window.onresize = function (event){
			var w = window.innerWidth;
			var h = window.innerHeight;
			//this part resizes the canvas but keeps ratio the same
			this_ref.pixi.renderer.view.style.width = w + "px";
			this_ref.pixi.renderer.view.style.height = h + "px";
			//this part adjusts the ratio:
			this_ref.pixi.renderer.resize(w,h);
			this_ref.game_width = w;
			this_ref.game_height = h;

			this_ref.drawGrid();
		}
	}

	onClose () {
		app.removeSearchGroup("Scene");
		nwFS.unlink(this.file);
		addScenes(app.project_path);
	}

	onMenuClick (e) {
		var this_ref = this;
		app.contextMenu(e.x, e.y, [
			{label:'close', click:function(){this_ref.close();}},
			{label:'rename', click:function(){this_ref.renameModal()}},
			{label:'delete', click:function(){this_ref.deleteModal()}},
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
			"yes": function() { this_ref.rename(filename, app.getElement('#new-file-name').value+".scene"); },
			"no": function() {}
		});
	}

	delete () {
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
			var stage_width =  this.game_width;
			var stage_height = this.game_height;

			if (!this.grid_graphics) {
				this.grid_graphics = new PIXI.Graphics();
				this.grid_container.addChild(this.grid_graphics);
			}

			this.grid_graphics.clear();
			this.grid_graphics.lineStyle(1, this.grid_color, this.grid_opacity);
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
		}
	}

	setCameraPosition (x, y) {
		this.camera = [x, y];
		// move grid
		this.grid_container.x = this.camera[0] % this.curr_layer.snap[0];
		this.grid_container.y = this.camera[1] % this.curr_layer.snap[1];

		this.refreshCamera();
	}

	refreshCamera () {
		this.map_container.setTransform(this.camera[0], this.camera[1]);
		this.drawCrosshair();
	}

	drawCrosshair () {
		if (this.curr_layer) {
			var snapx = this.curr_layer.snap[0];
			var snapy = this.curr_layer.snap[1];
			var stage_width =  this.game_width;
			var stage_height = this.game_height;

			let center = [
				this.place_mouse[0],
				this.place_mouse[1]
			];

			this.coord_text_x.x = this.place_mouse[0];
			this.coord_text_x.y = (this.game_height - this.place_mouse[1]) / 3 + this.place_mouse[1];
			this.coord_text_x.text = 'x '+this.mouse[0];

			this.coord_text_y.x = (this.game_width - this.place_mouse[0]) / 3 + this.place_mouse[0];
			this.coord_text_y.y = this.place_mouse[1];
			this.coord_text_y.text = 'y '+this.mouse[1];

			// line style
			this.origin_graphics.clear()
			this.origin_graphics.lineStyle(2, 0xffffff, this.grid_opacity);

			// horizontal
			this.origin_graphics.moveTo(0, this.place_mouse[1])
			this.origin_graphics.lineTo(stage_width, this.place_mouse[1]);
			// vertical
			this.origin_graphics.moveTo(this.place_mouse[0], 0);
			this.origin_graphics.lineTo(this.place_mouse[0], stage_height);
		}
	}

	// when object place type selector is changed
	refreshObjectType () {
		this.obj_type = this.el_sel_placetype.value;
		this.el_image_container.classList.add('hidden');
		this.el_object_container.classList.add('hidden');		
		
		if (this.obj_type == 'image' && this.curr_image) {
			this.el_image_container.classList.remove('hidden');
		}
		if (this.obj_type == 'object') {
			this.el_object_container.classList.remove('hidden');
		}
	}

	// refreshes combo box
	refreshLayerList (old_name, new_name) {
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

		let layer_list = this.layers.map(layer => layer.name);
		this.el_layer_control.setItems(layer_list);
		if (this.curr_layer)
			this.el_layer_control.selectItem(this.curr_layer.name);
	}

	// refreshes object combo box 
	refreshObjectList (obj_type='image') {
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

	// add all images in project to the search bar
	refreshImageList() {
		var this_ref = this;
		app.removeSearchGroup('scene_image');
		let walker = nwWALK.walk(nwPATH.join(app.project_path,'assets'));
		walker.on('file', function(path, stat, next){
			if (stat.isFile() && !stat.name.startsWith(".") && app.findAssetType(stat.name) == 'image') {
				let full_path = nwPATH.join(path, stat.name);
				var img_path = nwPATH.relative(app.project_path,full_path).replace(/assets[/\\]/,'');
				app.addSearchKey({key: img_path, group: 'scene_image', tags: ['image'], onSelect: function() {
					this_ref.setImage(nwPATH.resolve(full_path), function(img){			
						// set current image variable
						this_ref.curr_image = img;
						this_ref.refreshObjectType();
						this_ref.refreshImageGrid();
					});
				}});
			}
			next();
		});
	}

	// list of grid cells selected
	refreshImageSelectionList() {
		this.selected_xmin = -1;
		this.selected_ymin = -1;
		this.selected_width = -1;
		this.selected_height = -1;
		this.selected_image_frames = [];

		var el_image_frames = document.querySelectorAll('.image-grid > .cell.selected');
		let max_x = -1;
		let max_y = -1;
		if (el_image_frames) {
			for (var frame of el_image_frames) {
				let x = parseInt(frame.style.left);
				let y = parseInt(frame.style.top);
				let width = parseInt(frame.style.width);
				let height = parseInt(frame.style.height);

				this.selected_image_frames.push({
					'x':x,
					'y':y,
					'width':width,
					'height':height
				});

				if (this.selected_xmin == -1 || x < this.selected_xmin) this.selected_xmin = x;
				if (this.selected_ymin == -1 || y < this.selected_ymin) this.selected_ymin = y;

				if (x - this.selected_xmin + this.curr_image.snap[0] > this.selected_width)
					this.selected_width = x - this.selected_xmin + this.curr_image.snap[0];
				if (y - this.selected_ymin + this.curr_image.snap[1] > this.selected_height)
					this.selected_height = y - this.selected_ymin + this.curr_image.snap[1];
			}
		}
	}

	placeImageReady() {
		return this.obj_type == 'image' && this.curr_image && this.selected_image_frames.length > 0;
	}

	refreshImageGrid() {
		if (this.curr_image) {
			// update image info text
			this.el_image_info.innerHTML = app.getRelativePath(this.curr_image.path) + "<br/>" + this.curr_image.texture.width + " x " +  this.curr_image.texture.height;
			this.el_image_info.title = app.getRelativePath(this.curr_image.path);
			this.el_image_preview.src = "file://"+this.curr_image.path;	

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

	// remove current object type placed on canvas
	removeObject (x, y, obj_ref, layer_ref) {
		if (obj_ref && layer_ref) {
	    	let place_x = x - (x % (layer_ref.snap[0] / 2));
	    	let place_y = y - (y % (layer_ref.snap[1] / 2));
	    	let text_key = Math.floor(place_x).toString()+','+Math.floor(place_y).toString()+'.'+obj_ref.uuid;

			if (obj_ref.pixi_texts[text_key]) {
				obj_ref.pixi_texts[text_key].label.destroy();
				obj_ref.pixi_texts[text_key].destroy();
				delete obj_ref.pixi_texts[text_key];

				this_ref.export();
			}
		}
	}

	// when user presses enter to finish object
	// also used when loading a file's objects
	placeObject (points) {
		let this_ref = this;

		if (points.length > 2) {
			// make sure points don't form a straight line
			let slope_changes = 0;
			let slope = null;
			for (let p = 2; p < points.length; p+=2) {
				let x1 = points[p-2], y1 = points[p-1];
				let x2 = points[p], y2 = points[p+1];

				let new_slope = (y2 - y1) / (x2 - x1);

				if (new_slope != slope) {
					if (slope !== null)
						slope_changes++;
					slope = new_slope;
				}
			}
			if (slope_changes == 0) return; // REJECTED!!
		}

		let curr_object = this.curr_object;
		let pixi_poly = new PIXI.Graphics();

		// add polygon points
		pixi_poly.lineStyle(2, parseInt(curr_object.color.replace('#',"0x"),16), .5);
		pixi_poly.beginFill(parseInt(curr_object.color.replace('#',"0x"),16), .25);
		if (points.length == 2) {
			pixi_poly.drawRect(
				points[0]-this.curr_layer.snap[0]/2,
				points[1]-this.curr_layer.snap[1]/2,
				this.curr_layer.snap[0],this.curr_layer.snap[1]
			);
		} else {
			for (let p = 0; p < points.length; p+=2) {
				if (p == 0)
					pixi_poly.moveTo(points[p], points[p+1]);
				else
					pixi_poly.lineTo(points[p], points[p+1]);
			}
			pixi_poly.lineTo(points[0], points[1]);
		}
		pixi_poly.endFill();

		// add remove click
		pixi_poly.interactive = true;
		pixi_poly.on('rightup', function(e){
			// remove from array
			if (!this_ref.placing_object && this_ref.obj_type == 'object' && this_ref.curr_object.name == curr_object.name) {
				let del_uuid = e.target.uuid;
				this_ref.iterObjectInLayer(this_ref.curr_layer.uuid, curr_object.name, function(obj, o){
					if (del_uuid == obj.poly.uuid) {
						e.target.destroy();
						return true;
					}
				});
				this_ref.export();
			}
		});

		pixi_poly.uuid = guid();
		this.curr_layer.container.addChild(pixi_poly);

		curr_object.pixi_texts.push({
			poly: pixi_poly,
			points: points,
			layer_uuid: this.curr_layer.uuid,
			layer_name: this.curr_layer.name
		});
	}

	clearPlacingObject () {
		if (!this.placing_object) return;

		this.placing_object.graphic.destroy();
		for (let g_dot of this.placing_object.graphic_dots) {
			g_dot.destroy();
		}
		this.placing_object = null;
	}

	removeObjectPoint () {
		if (this.placing_object) {
			// remove a point
			this.placing_object.points.pop();
			this.placing_object.points.pop();

			this.redrawPlacingObject();

			if (this.placing_object.points.length < 2) 
				this.clearPlacingObject();
			
		}
	}

	redrawPlacingObject () {
		// redraw polygon
		this.placing_object.graphic.clear();
		this.placing_object.graphic.beginFill(parseInt(this.curr_object.color.replace('#',"0x"),16), .5);
		this.placing_object.graphic_dots.map(obj => obj.destroy());
		this.placing_object.graphic_dots = [];

		let vertices = this.placing_object.points;//earcut(this.placing_object.points, null, 2);

		let avgx = 0;
		let avgy = 0;
		for (let p = 0; p < vertices.length; p+=2) {
			let ptx = vertices[p];
			let pty = vertices[p+1];
			avgx += ptx;
			avgy += pty;

			if (p == 0)
				this.placing_object.graphic.moveTo(ptx, pty);
			else
				this.placing_object.graphic.lineTo(ptx, pty);

			// add dot to show point
			let new_graphic = new PIXI.Graphics();
			new_graphic.beginFill(parseInt(this.curr_object.color.replace('#',"0x"),16), .75);
			new_graphic.drawRect(ptx-2,pty-2,4,4);
			new_graphic.endFill();
			this.curr_layer.container.addChild(new_graphic);
			this.placing_object.graphic_dots.push(new_graphic);
		}	
		if (vertices.length > 2) {
			avgx /= (vertices.length)/2;
			avgy /= (vertices.length)/2;	
		}
		this.placing_object.graphic.endFill();

		this.curr_layer.container.addChild(this.placing_object.graphic);
	}

	placeObjectPoint (x, y) {
		var this_ref = this;
		var curr_object = this.curr_object;

		if (curr_object && this.curr_layer) {
			// place a vertex
			if (!this.placing_object) {
				// first vertex
				this.placing_object = {
					graphic: new PIXI.Graphics(),
					graphic_dots: [],	// add later
					points: []
				}
			}

			// calculate snap
			let snapx = this.curr_layer.snap[0] / 2;
			let snapy = this.curr_layer.snap[1] / 2;
			if (x < 0) x -= snapx;
			if (y < 0) y -= snapy;
			if (this.snap_on) {
				x -= x % snapx;
				y -= y % snapy;
			}

			// add to main shape
			this.placing_object.points.push(x, y);

			this.redrawPlacingObject();
		}
	}

	placeImageFrame (x, y, frame, img_ref, layer, from_load) {
		if (!layer) layer = this.curr_layer;
		let place_image = img_ref;

		let new_tile_texture;

		try {
			new_tile_texture = new PIXI.Texture(
	            place_image.texture,
	            new PIXI.Rectangle(frame.x, frame.y, frame.width, frame.height)
	        );
       		new_tile_texture.layer_uuid = layer.uuid;
       	} catch (error) {
       		blanke.toast("Error loading '"+img_ref.path+"'");
       	}

        if (!new_tile_texture) return;

		let new_tile = {'x':0,'y':0,'w':0,'h':0,'snapped':false};

		if (!from_load) {
			let offx = 0, offy = 0;
			// if (x - this.camera[0] < 0) offx = layer.snap[0];
			// if (y - this.camera[1] < 0) offy = layer.snap[1];

			x += (frame.x - this.selected_xmin);
			y += (frame.y - this.selected_ymin);
				
			let align = place_image.align || "top-left";

			if (this.snap_on && !from_load) {
				x -= x % layer.snap[0];
				y -= y % layer.snap[1];
				new_tile.snapped = true;
			}

			if (align.includes("right"))
				x -= this.selected_width;
			if (align.includes("bottom"))
				y -= this.selected_height;

			
		}

		let text_key = Math.floor(x).toString()+','+Math.floor(y).toString()+'.'+layer.uuid;

		// add if a tile isn't already there
		if (from_load || !place_image.pixi_images[text_key]) {
			if (!place_image.pixi_tilemap[layer.uuid]) {
				place_image.pixi_tilemap[layer.uuid] = new PIXI.Container();
				layer.container.addChild(place_image.pixi_tilemap[layer.uuid]);

				layer.container.setChildIndex(place_image.pixi_tilemap[layer.uuid], 0);
			}


			let new_sprite = new PIXI.Sprite(new_tile_texture);
			new_sprite.x = x;
			new_sprite.y = y;
			place_image.pixi_tilemap[layer.uuid].addChild(new_sprite);
			
			//place_image.pixi_tilemap[layer.uuid].addFrame(new_tile_texture,x,y);
			new_tile.x = x;
			new_tile.y = y;
			new_tile.frame = frame;
			new_tile.texture = new_tile_texture;
			new_tile.sprite = new_sprite;

			new_tile.uuid = place_image.uuid;
			new_tile.text_key = text_key;
			new_tile.layer_name = layer.name;
			new_tile.layer_uuid = layer.uuid;
			place_image.pixi_images[text_key] = new_tile;
		}
	}

	placeImage (x, y, img_ref, layer) {
		if (this.curr_image && this.curr_layer) {
			for (var frame of this.selected_image_frames) {
				this.placeImageFrame(x, y, frame, img_ref, layer);
			}
		}
	}

	// uses curr_image and curr_layer
	redrawTiles () {
		return; // FUNCTION NOT USED ATM. MAY REMOVE SOON
		if (!this.curr_image) return;

		// redraw all tiles 
		for (var layer_uuid in this.curr_image.pixi_tilemap) {
			this.curr_image.pixi_tilemap[layer_uuid].removeChildren(); //.clear();
			for (var t in this.curr_image.pixi_images) {
				let tile = this.curr_image.pixi_images[t];
				
				let new_sprite = new PIXI.Sprite(tile.texture);
				new_sprite.x = tile.x;
				new_sprite.y = tile.y;
				this.curr_image.pixi_tilemap[layer_uuid].addChild(new_sprite);
				// this.curr_image.pixi_tilemap[layer_name].addFrame(tile.texture,tile.x,tile.y);

			}
			
			// refresh opacity
			
			//if (layer_name != this.curr_layer.uuid)
			//	this.getLayer(layer_name, true).container.alpha = 0.25;
		}
	}

	// return true if object should be removed
	iterObject (name, func) {
		for (var l = 0; l < this.objects.length; l++) {
			if (this.objects[l].name === name) {
				var new_array = [];
				for (var t in this.objects[l].pixi_texts) {
					if (this.objects[l].pixi_texts[t]) {
						let remove_obj = func(this.objects[l].pixi_texts[t], t);
						if (!remove_obj) new_array.push(this.objects[l].pixi_texts[t]);
					}
				}
				this.objects[l].pixi_texts = new_array;
				return;
			}
		}
	}

	// return true if object should be removed
	iterObjectInLayer (layer_uuid, name, func) {
		for (var l = 0; l < this.objects.length; l++) {
			var new_array = [];
			if (this.objects[l].name === name) {
				for (var t in this.objects[l].pixi_texts) {
					if (this.objects[l].pixi_texts[t].layer_uuid == layer_uuid) {
						let remove_obj = func(this.objects[l].pixi_texts[t], t);
						if (!remove_obj) new_array.push(this.objects[l].pixi_texts[t]);
					}
				}
				this.objects[l].pixi_texts = new_array;
				return;
			}
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

		info.pixi_texts = [];
		this.objects.push(info);
		this.refreshObjectList();
		this.setObject(info.name);

		this.drawDotPreview();
	}

	drawDotPreview () {
		if (!this.dot_preview) {
			this.dot_preview = new PIXI.Graphics();
			this.map_container.addChild(this.dot_preview);	
		}

		if (this.obj_type == "object" && this.curr_object) {
			let snapx = this.curr_layer.snap[0] / 2;
			let snapy = this.curr_layer.snap[1] / 2;
			let x = this.mouse[0]-this.camera[0];
			let y = this.mouse[1]-this.camera[1];
			if (x < 0) x -= snapx;
			if (y < 0) y -= snapy;
			if (this.snap_on) {
				x -= x % snapx;
				y -= y % snapy;
			}

			this.dot_preview.clear();
			this.dot_preview.beginFill(parseInt(this.curr_object.color.replace('#',"0x"),16), .75);
			this.dot_preview.drawRect(x-2,y-2,4,4);
			this.dot_preview.endFill();
		} else {
			this.dot_preview.clear();
		}
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

				this.iterObjectInLayer (this.curr_layer.uuid, name, function(obj, o){
					bringToFront(obj.poly);
				});
				return;
			}
		}	
	}

	getImage (path) {
		path = app.cleanPath(path);
		for (let img of this.images) {
			if (img.path == path)
				return img;
		}
	}

	loadImageTexture (img, onReady) {
		let image_obj = new Image();
		image_obj.onload = function(){
			let base = new PIXI.BaseTexture(image_obj);
			let texture = new PIXI.Texture(base);

			// save texture info
			img.texture = texture;	

			if (onReady) onReady(img);
		}
		image_obj.src = "file://"+img.path;
	}

	setImage (path, onReady) {
		path = app.cleanPath(path);
		let img = this.getImage(path);
		if (img) {
			this.loadImageTexture(img, onReady);
			
			// set image inputs
			for (var property of ['snap', 'offset', 'spacing']) {
				this.el_image_form.setValue(property, img[property][0], 0);
				this.el_image_form.setValue(property, img[property][1], 1);
			}
			this.el_image_form.setValue('align', img.align || "top-left");
		}
		// add image to scene library
		else {
			this.images.push({
				path: path,
				snap: this.curr_layer.snap.slice(0),
				offset: [0,0],
				spacing: [0,0],
				align: 'top-left',
				uuid: guid(),
				pixi_images: {},
				pixi_tilemap: {}
			});
			this.export();
			this.setImage(path, onReady);
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

		info.snap = info.snap.map(Number);

		info.container = new PIXI.Container();
		this.map_container.addChild(info.container);
		this.layers.push(info);
		this.setLayer(info.name);

		return info.name;
	}

	getLayer (name, is_uuid) {
		for (var l = 0; l < this.layers.length; l++) {
			if ((is_uuid && this.layers[l].uuid == name) || this.layers[l].name === name) 
				return this.layers[l];
		}
	}

	setLayer (name) {
		for (var l = 0; l < this.layers.length; l++) {
			if (this.layers[l].name === name) {
				this.curr_layer = this.layers[l];
				this.el_layer_form.setValue('name', this.curr_layer.name);
				this.el_layer_form.setValue('snap', this.curr_layer.snap[0], 0);
				this.el_layer_form.setValue('snap', this.curr_layer.snap[1], 1);
				this.layers[l].container.alpha = 1;
				
				this.el_layer_control.selectItem(name);

			} else {
				// make other layers transparent
				this.layers[l].container.alpha = 0.25;
			}
			this.map_container.setChildIndex(this.layers[l].container, this.map_container.children.length-1);
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
			this.refreshLayerList();

			// images
			let this_ref = this;
			data.images.forEach(function(img, i){
				var full_path = nwPATH.normalize(nwPATH.resolve(app.project_path,img.path));
				this_ref.images.push({
					path: app.cleanPath(full_path),
					snap: img.snap,
					offset: img.offset,
					spacing: img.spacing,
					align: img.align,
					uuid: img.uuid,
					pixi_images: {},
					pixi_tilemap: {}
				});
				this_ref.setImage(full_path, function(img_ref){
					for (var layer_name in img.coords) {
						let layer = this_ref.getLayer(layer_name);
						for (var coord of img.coords[layer_name]) {
							this_ref.placeImageFrame(coord[0], coord[1], {
								'x':coord[2], 'y':coord[3], 'width':coord[4], 'height':coord[5]
							}, img_ref, layer, true);
						}
					}

				});				
			});


			// objects
			for (var o = 0; o < data.objects.length; o++) {
				var obj = data.objects[o];
				this.addObject(obj);

				for (var layer_name in obj.polygons) {
					this.setLayer(layer_name);
					for (var c = 0; c < obj.polygons[layer_name].length; c++) {
						this.placeObject(obj.polygons[layer_name][c]);
					}
				}
			}

			if (data.objects.length > 0) 
				this.updateGlobalObjList();

			else {
				for (var o = 0; o < global_objects.length; o++) {
					this.addObject(global_objects[o]);
				}
			}

			this.refreshObjectList();

			// settings
			if (data.settings) {
				this.setCameraPosition(data.settings.camera[0], data.settings.camera[1]);
			}
		}

		this.setTitle(nwPATH.basename(file_path));
	}

	export () {
		if (this.deleted) return;

		let export_data = {'objects':[], 'layers':[], 'images':[], 'settings':{
			camera:this.camera
		}};
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
				polygons: {}
			}
			for (let t in obj.pixi_texts) { 
				if (obj.pixi_texts[t] && layer_names[obj.pixi_texts[t].layer_name]) {
					if (!exp_obj.polygons[obj.pixi_texts[t].layer_name])
						exp_obj.polygons[obj.pixi_texts[t].layer_name] = [];

					exp_obj.polygons[obj.pixi_texts[t].layer_name].push(obj.pixi_texts[t].points.slice());
				}
			}
			export_data.objects.push(exp_obj);
		}

		//images
		for (let obj of this.images) {
			let img_path = app.cleanPath(nwPATH.relative(app.project_path,obj.path));
			let exp_img = {
				path: img_path,
				snap: obj.snap,
				offset: obj.offset,
				spacing: obj.spacing,
				align: obj.align,
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

			// only save image if it was used
			if (Object.keys(obj.pixi_images).length > 0)
				export_data.images.push(exp_img);
		}

		nwFS.writeFileSync(this.file, JSON.stringify(export_data));
	}
}

document.addEventListener('fileChange', function(e){
	if (e.detail.type == 'change') {
		app.removeSearchGroup("Scene");
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
							if (!Tab.focus(nwPATH.basename(file_path)))
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

document.addEventListener("closeProject", function(e){	
	app.removeSearchGroup("Scene");
});

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