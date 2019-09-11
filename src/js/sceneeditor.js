// rework object editor:
// - (DONE) click empty space: add rectangle object
// - (DONE) click on edge of object (point is on edge): add point in between points of edge
// - can drag points (important)

// var earcut = require('./includes/earcut.js');

// http://www.html5gamedevs.com/topic/7507-how-to-move-the-sprite-to-the-top/?do=findComment&comment=45162
function bringToFront(sprite, parent) {var sprite = (typeof(sprite) != "undefined") ? sprite.target || sprite : this;var parent = parent || sprite.parent || {"children": false};if (parent.children) {    for (var keyIndex in sprite.parent.children) {         if (sprite.parent.children[keyIndex] === sprite) {            sprite.parent.children.splice(keyIndex, 1);            break;        }    }    parent.children.push(sprite);}}
function sendToBack(sprite, parent) {var sprite = (typeof(sprite) != "undefined") ? sprite.target || sprite : this;var parent = parent || sprite.parent || {"children": false};if (parent.children) {    for (var keyIndex in sprite.parent.children) {          if (sprite.parent.children[keyIndex] === sprite) {            sprite.parent.children.splice(keyIndex, 1);            break;        }    }    parent.children.splice(0,0,sprite);    }}

PIXI.loader.add('ProggyScene','includes/proggy_scene.fnt');
PIXI.loader.load();

let map_folder = () => nwPATH.join(app.project_path,'assets','maps');

class SceneEditor extends Editor {
	constructor (file_path) {
		super();
		this.setupFibWindow(true);

		var this_ref = this;

		this.file = '';
		
		this.grid_opacity = 0.05;
		this.snap_on = true;
		this.deleted = false;

		this.obj_type = '';
		this.curr_layer = {snap:[1,1]};
		this.curr_object = null;	// reference from this.objects[]
		this.curr_image	= null;		// reference from this.images[]
		this.layers = [];
		this.objects = [];			// all objects placed on the canvas
		this.obj_polys = {};
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

		PIXI.scaleModes.DEFAULT = PIXI.scaleModes.NEAREST;
		this.pixi = new PIXI.Application(this.game_width, this.game_height, {
			backgroundColor: 0x354048,// 0x424242,
			antialias: false//,
			//resizeTo: app.getElement("#bg-workspace")
		});
		this.grid_color = 0xBDBDBD;
		this.appendBackground(this.pixi.view);

		this.pixi.stage.interactive = true;
		this.pixi.stage.hitArea = this.pixi.screen;
		this.pixi.view.addEventListener('contextmenu', (e) => {
			e.preventDefault();
		});

		// create map container
		this.overlay_container = new PIXI.Container();	// displayed above everything
		this.map_container = new PIXI.Container();
		this.pixi.stage.addChild(this.map_container);

		this.grid_container = new PIXI.Container()
		this.grid_graphics = new PIXI.Graphics();		// position wraps based on layer snap
		this.origin_graphics = new PIXI.Graphics();
		this.crosshair_graphics = new PIXI.Graphics();
		this.coord_text_style = {font:{size:16, name:"proggy_scene"}};

		this.coord_text = new PIXI.extras.BitmapText('x 0 y 0', this.coord_text_style);
		this.obj_info_text = new PIXI.extras.BitmapText('', this.coord_text_style);
		this.obj_info = {};

		this.overlay_container.addChild(this.coord_text);
		this.overlay_container.addChild(this.obj_info_text);

		// this.grid_container.addChild(this.origin_graphics);
		this.grid_container.addChild(this.grid_graphics);
		this.overlay_container.addChild(this.origin_graphics);
		this.overlay_container.addChild(this.crosshair_graphics);

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
		this.el_image_sel 		= app.createElement("select","image-select");
		this.el_image_info 		= app.createElement("p","image-info");
		this.el_image_container	= app.createElement("div","image-container");
		this.el_image_tiles_container = app.createElement("div","image-tiles-container")
		this.el_image_preview	= app.createElement("img","image-preview");
		this.el_image_grid		= app.createElement("div","image-grid");

		this.el_image_container.classList.add('hidden');

		// OBJECT elements
		this.el_object_container= app.createElement("div","object-container");

		this.el_object_form = new BlankeForm([
			['name', 'text'],//, {'label':false}],
			['color', 'color', {'label':false}],
			['size', 'number', {'inputs':2, 'separator':'x'}],
			['delete', 'button']
		]);
		this.el_object_form.container.style.display = "none";
	
		this.el_layer_container	= app.createElement("div","layer-container");
		this.el_snap_container	= app.createElement("div","snap-container");
		this.el_snap_label		= app.createElement("p","snap-label");
		this.el_snap_x			= app.createElement("input","snap-x");
		this.el_snap_y			= app.createElement("input","snap-y");
		this.el_snap_sep		= app.createElement("p","snap-sep");

		this.el_sel_placetype 	= app.createElement("select","select-placetype");
		this.el_input_object	= app.createElement("input","input-object");
		// add object types
		let obj_types = ['image','object','tag'];
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
		this.el_image_sel.addEventListener('change',(e)=>{
			this_ref.setImage(e.target.options[e.target.selectedIndex].value, function(img){			
				// set current image variable
				this_ref.curr_image = img;
				this_ref.refreshObjectType();
				this_ref.refreshImageGrid();
			});
		});

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
				this_ref.curr_image.align = value;
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
			e.preventDefault();
		}
		this.el_image_grid.addEventListener('mousemove',selectImageTiles);
		this.el_image_grid.addEventListener('mousedown',selectImageTiles);
		this.el_image_grid.addEventListener("contextmenu", (e) => { e.preventDefault(); });

		// OBJECT elements

		// object name
		this.el_object_form.onChange('name', function(value){
			if (this_ref.curr_object) {
				if (value == '')
					return this_ref.curr_object.name;
				else {
					delete this_ref.obj_info[this_ref.curr_object.name];
					this_ref.el_obj_list.renameItem(this_ref.curr_object.name, value);
					this_ref.curr_object.name = value;
					this_ref.iterObject(this_ref.curr_object.name, function(obj) {
						this_ref.drawObjImage(this_ref.curr_object, obj.image, obj.points);
					});
					this_ref.export();
				}
			}
		});

		// object color
		this.el_object_form.onChange('color', function(value){
			if (this_ref.curr_object) {
				this_ref.curr_object.color = value;
				this_ref.iterObject(this_ref.curr_object.name, function(obj) {
					this_ref.drawPoly(this_ref.curr_object, obj.points, obj.poly);
				});
				this_ref.el_obj_list.setItemColor(this_ref.curr_object.name, value);
				this_ref.export();
			}
		});

		// object size
		this.el_object_form.onChange('size', function(value){
			let sizex = value[0];
			let sizey = value[1];

			if (this_ref.curr_object) {
				if (isNaN(sizex) || isNaN(sizey))
					return this_ref.curr_object.size.slice();

				if (sizex < 0) sizex = 0;
				if (sizey < 0) sizey = 0;
				this_ref.curr_object.size[0] = sizex;
				this_ref.curr_object.size[1] = sizey;

				this_ref.iterObject(this_ref.curr_object.name, function(obj) {
					this_ref.drawPoly(this_ref.curr_object, obj.points, obj.poly);
				});

				this_ref.export();
			}
		});

		// object deletion
		this.el_object_form.onChange('delete', function(){
			if (this_ref.curr_object) {
				for (let uuid in this_ref.objects) { 
					if (uuid == this_ref.curr_object.uuid) {
						let obj = this_ref.objects[uuid];
						blanke.showModal(
							"<label>Remove '"+obj.name+"'?<br/>Objects are global and it will be removed from all maps.</label>",
						{
						"yes": function() {
							// remove instances
							this_ref.iterObject(obj.name, function(obj) {
								consoe.log(obj)
								obj.image.destroy();
								obj.poly.destroy();
							});

							// remove the object
							this_ref.setObject(this_ref.el_obj_list.removeItem(obj.name, true));
							this_ref.deleteObject(uuid);
				 		},
							"no": function() {}
						});

						break;
					}
				}
			}
		});

		// add object button
		this.el_obj_list = new BlankeListView({object_type:"object"});
		this.el_obj_list.onItemSelect = function(text) {
			this_ref.setObject(text);	
		}
		this.el_obj_list.onItemAdd = function(text) {
			this_ref.addObject({name:text});
			this_ref.export();
			return false;
		}
		this.el_obj_list.onItemSwap = function(text1, text2) {
			let obj1, obj2;
			for (let uuid in this_ref.objects) {
				if (this_ref.objects[uuid].name == text1) obj1 = uuid;
				if (this_ref.objects[uuid].name == text2) obj2 = uuid;
			}
			let new_list = {};
			Object.keys(this_ref.objects).map(key => (key == obj1) ? obj2 : (key == obj2) ? obj1 : key)
				.forEach(function(key){
					new_list[key] = this_ref.objects[key];
				});
			this_ref.objects = new_list;
			this_ref.export();
		}

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

		this.el_layer_list = new BlankeListView({
			title:'layers',
			options:['add'],
			object_type:'layer',
			actions:{
				"delete":"remove layer"
			}
		});
		this.el_layer_list.onItemAction = function(icon, text) {
			if (icon == "delete") {
				blanke.showModal(
					"delete \'"+text+"\'?",
					{
						"yes": function() { this_ref.removeLayer(text); },
						"no": function() {}
					}
				);
				
			}
		}
		this.el_layer_list.onItemSelect = function(text) {
			this_ref.setLayer(text);
			this_ref.export();
		}
		this.el_layer_list.onItemAdd = function(text) {
			this_ref.addLayer({name:text});
			this_ref.export();
			return false;
		}
		this.el_layer_list.onItemSwap = function(text1, text2) {
			let lay1, lay2;
			for (var l = 0; l < this_ref.layers.length; l++) {
				if (this_ref.layers[l].name == text1) lay1 = l;
				if (this_ref.layers[l].name == text2) lay2 = l;
			}
			let temp_lay = this_ref.layers[lay1];
			this_ref.layers[lay1] = this_ref.layers[lay2];
			this_ref.layers[lay2] = temp_lay;
			this_ref.refreshLayers();
			this_ref.export();
		}

		// hide/show scene menu
		this.el_toggle_sidebar = app.createElement("button", "ui-button-sphere");
		this.el_toggle_sidebar.id = "toggle-scene-sidebar";
		this.el_toggle_sidebar.innerHTML = "<i class='mdi mdi-light mdi-page-layout-sidebar-right'></i>";
		this.el_toggle_sidebar.onclick = function() {
			this_ref.el_sidebar.classList.toggle("hidden");
		}

		// TAG
		this.el_tag_form = new BlankeForm([
			['value', 'text', {'label':false}]
		]);
		this.el_tag_form.container.classList.add("tag-container");

		// LAYER
		this.el_layer_container.appendChild(this.el_layer_list.container);
		this.el_layer_container.appendChild(this.el_layer_form.container);

		// OBJECT
		this.el_object_container.appendChild(this.el_obj_list.container);
		this.el_object_container.appendChild(this.el_object_form.container);

		// IMAGE
		this.el_image_container.appendChild(this.el_image_info);
		this.el_image_container.appendChild(this.el_image_form.container);
		this.el_image_tiles_container.appendChild(this.el_image_preview);
		this.el_image_tiles_container.appendChild(this.el_image_grid);
		this.el_image_container.appendChild(this.el_image_tiles_container);

		this.el_sidebar.appendChild(this.el_layer_container);
		this.el_sidebar.appendChild(this.el_sel_placetype);
		this.el_sidebar.appendChild(this.el_object_container);
		this.el_sidebar.appendChild(this.el_image_sel);
		this.el_sidebar.appendChild(this.el_image_container);
		this.el_sidebar.appendChild(this.el_tag_form.container);

		this.appendChild(this.el_sidebar);
		// this.appendChild(this.el_toggle_sidebar); // commented out for SideWindow changes

		// Pointer Locking for camera dragging
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
				this_ref.export();
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
		this.pixi.view.addEventListener('mouseenter', function(e){
			this_ref.can_drag = true;
		});
		this.pixi.view.addEventListener('mouseout', function(e){
			if (!this_ref.dragging) this_ref.can_drag = false;
		});

		// Zoom control
		this.zoom = 1;
		this.zoom_target = 1;
		this.zoom_incr = 0.1;
		this.old_cam = [0,0];
		window.addEventListener('wheel',(e)=>{
			/*
			e.preventDefault();
			this_ref.setZoom(this_ref.zoom - (Math.sign(e.deltaY) * this.zoom_incr))
			*/
		});
		
		this.tile_start = [0,0];
		this.tile_straightedge = new PIXI.Graphics();
		this.map_container.addChild(this.tile_straightedge);

        this.pointer_down = -1;
		this.pixi.stage.on('pointerdown',function(e){
			let x = this_ref.mouse[0];
			let y = this_ref.mouse[1];
			let btn = e.data.originalEvent.button;
			let alt = e.data.originalEvent.altKey;

			this_ref.pointer_down = btn;

			// dragging canvas
			if (btn == 1 && !this_ref.dragging) {
				this_ref.can_drag = true;
				this_ref.pixi.view.style.cursor = "all-scroll";
				dragStart();
			}

			if (!alt && !this_ref.dragging) {
				// placing object
				if (btn == 0) {
					if(this_ref.obj_type == 'object') 
						this_ref.placeObjectPoint(this_ref.half_mouse[0], this_ref.half_mouse[1]);
					
					if(this_ref.obj_type == 'image') {
						this_ref.tile_start = [x,y];
						bringToFront(this.tile_straightedge)
					}
				}

				// removing object/tile
				if (btn == 2) {
					if (this_ref.obj_type == 'object') {
						this_ref.removeObjectPoint();
					}
					if (this_ref.obj_type == 'image' && this_ref.curr_image) {
						this_ref.deleteTile(this_ref.mx,this_ref.my);
                    }
				}

				if (this_ref.obj_type) 
					this_ref.export();
			}
		});

		this.pixi.stage.on('pointerup',function(e){
			let x = this_ref.mouse[0];
			let y = this_ref.mouse[1];
			let btn = e.data.originalEvent.button;
			let alt = e.data.originalEvent.altKey; 
        	this_ref.pointer_down = -1;


			if (btn == 1 && this_ref.dragging) {
				this_ref.can_drag = true;
				this_ref.pixi.view.style.cursor = "auto";
				dragStop();
			}

			if (btn == 2) {

			}

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

						this_ref.export();
					}
				}
			}
		});

		this.place_mouse = [0,0];
		this.half_mouse = [0,0];
		this.half_place_mouse = [0,0];
		this.lock_mouse = false;
		this.mx = 0;
		this.my = 0;
		this.pixi.stage.on('pointermove', function(e) {
			// mouse screen coordinates
			let x = e.data.global.x;
			let y = e.data.global.y;
			let btn = this_ref.pointer_down;
			let alt = e.data.originalEvent.altKey; 

			// camera dragging
			if (this_ref.dragging) {
				this_ref.setCameraPosition(
					this_ref.camera[0] + e.data.originalEvent.movementX,
					this_ref.camera[1] + e.data.originalEvent.movementY
				)
			}
		
			let snapx = 1, snapy = 1;	
			if (this_ref.curr_layer) {
				snapx = this_ref.curr_layer.snap[0];
				snapy = this_ref.curr_layer.snap[1];
			}

			x /= this_ref.zoom;
			y /= this_ref.zoom;
				
			// mouse world coordinates
			let mx = x-(this_ref.camera[0] / this_ref.zoom),
				my = y-(this_ref.camera[1] / this_ref.zoom);
			this_ref.mx = mx;
			this_ref.my = my;

			this_ref.place_mouse = [Math.floor(x * this_ref.zoom),Math.floor(y * this_ref.zoom)];
			this_ref.mouse = [Math.floor(mx),Math.floor(my)];
			this_ref.half_mouse = [Math.floor(mx), Math.floor(my)];
			this_ref.half_place_mouse = [Math.floor(x),Math.floor(y)];

			if ((!e.data.originalEvent.ctrlKey || this_ref.obj_type == "object") && !this_ref.dragging) {
				if (mx < 0) { mx -= snapx; x -= snapx; }
				if (my < 0) { my -= snapy; y -= snapy; }

				// use: placing images, displaying mouse coordinates
				this_ref.mouse = [
					mx - (mx%snapx),
					my - (my%snapy)
				];
				// use: drawing crosshair
				this_ref.place_mouse = [
					(x * this_ref.zoom) - (mx % snapx  * this_ref.zoom),
					(y * this_ref.zoom) - (my % snapy * this_ref.zoom)
				]

				if (mx < 0) { mx += snapx/2; x += snapx/2; }
				if (my < 0) { my += snapy/2; y += snapy/2; }
				// use: placing object points, displaying mouse coordinates
				this_ref.half_mouse = [
					mx - (mx%(snapx/2)),
					my - (my%(snapy/2))
				];
				// use: drawing crosshair
				this_ref.half_place_mouse = [
					(x * this_ref.zoom) - (mx % (snapx/2.0)  * this_ref.zoom),
					(y * this_ref.zoom) - (my % (snapy/2.0) * this_ref.zoom)
				]
			}

			this_ref.drawCrosshair();

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
                        this_ref.deleteTile(mx, my);                                
                    //});
				}
            }

			this_ref.drawDotPreview();
		});
        
		// moving camera with arrow keys
		document.addEventListener('keydown', function(e){
			if (document.activeElement === document.body && this_ref.curr_layer) {
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

				this_ref.setCameraPosition(this_ref.camera[0] + vx, this_ref.camera[1] + vy);

				// show camera grabbing hand
				if (e.key == "Alt") {
					this_ref.pixi.view.style.cursor = "all-scroll";
					this_ref.pixi.view.requestPointerLock();
					dragStart();
				}

				/* TODO: cancel things 
				if (e.key == "Esc") {
        			this_ref.pointer_down = -1;

        			// ... like placing tiles in a line
				}*/
			}
		});

		document.addEventListener('keyup', function(e){
			if (document.activeElement === document.body) {
				this_ref.pixi.view.style.cursor = "auto";

				if (e.key == "Alt") {
					// release mouse
					dragStop();
					document.exitPointerLock();
				}
				
				if (e.key == "-") {
					// zoom out
					this_ref.setZoom(this_ref.zoom - this_ref.zoom_incr);
				}

				if (e.key == "=") {
					// zoom out
					this_ref.setZoom(this_ref.zoom + this_ref.zoom_incr);
				}

				if (e.key == "0") {
					// reset zoom
					this_ref.setZoom(1);
				}
			}
		});

		this.pixi.stage.addChild(this.map_container);
		this.pixi.stage.addChild(this.grid_container);
		this.pixi.stage.addChild(this.overlay_container);

		
		// tab focus
		this.has_focus = true;
		this.addCallback("onTabFocus", function(){
			this_ref.refreshImageList();
			this_ref.loadObjectsFromSettings();
			// refresh image aligns
			this_ref.iterObject(this_ref.curr_object.name, function(obj) {
				this_ref.drawObjImage(this_ref.curr_object, obj.image, obj.points);
			});
			this_ref.has_focus = true;
		});
		this.addCallback("onTabLostFocus", function(){
			this_ref.export();
			this_ref.has_focus = false;
		});

		this.obj_type = 'object';
		this.refreshObjectType();

		document.addEventListener('fileChange', function(e){
			if (e.detail.type == 'change' && this_ref.has_focus) {
				if (this_ref.curr_image && app.findAssetType(e.detail.file) == "image")
					this_ref.refreshImageList();
			}
		});

		this.addCallback('onResize', this.resizeEditor.bind(this));

		if (file_path) this.load(file_path);
	}

	resizeEditor () {
		let parent = this.pixi.view.parentElement;
		if (!parent) return;
		let w = parent.clientWidth;
		let h = parent.clientHeight;
		/*
		let w = this.bg_width;
		let h = this.bg_height;
		*/

		this.pixi.renderer.view.style.width = w + "px";
		this.pixi.renderer.view.style.height = h + "px";
		//this part adjusts the ratio:
		this.pixi.renderer.resize(w,h);
		this.game_width = w;
		this.game_height = h;

		this.drawGrid();
	}

	onClose () {
		app.removeSearchGroup("Scene");
		//nwFS.unlink(this.file);
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
		let new_path = nwPATH.dirname(this.file)+"/"+new_name;
		
		app.renameSafely(old_path, new_path, (success) => {
			if (success) {
				this_ref.file = new_path;
				this_ref.setTitle(nwPATH.basename(this_ref.file));
				SceneEditor.refreshSceneList();
			} else
				blanke.toast("could not rename \'"+nwPATH.basename(old_path)+"\'");
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
		nwFS.remove(this.file);
		//app.onFileRemoved(this.file);
		this.deleted = true;
		SceneEditor.refreshSceneList();
		this.close(true);
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
			var stage_width =  this.game_width / this.zoom;
			var stage_height = this.game_height / this.zoom;

			if (!this.grid_graphics) {
				this.grid_graphics = new PIXI.Graphics();
				this.grid_container.addChild(this.grid_graphics);
			}

			this.grid_graphics.clear();
			this.grid_graphics.lineStyle(1/this.zoom, this.grid_color, this.grid_opacity);
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
			var stage_width =  this.game_width;
			var stage_height = this.game_height;

			// origin line
			this.origin_graphics.clear()
			this.origin_graphics.lineStyle(1, this.grid_color, .25);

			// horizontal
			this.origin_graphics.moveTo(0, this.camera[1])
			this.origin_graphics.lineTo(stage_width, this.camera[1]);
			// vertical
			this.origin_graphics.moveTo(this.camera[0], 0);
			this.origin_graphics.lineTo(this.camera[0], stage_height);
		}
	}

	updateZoom () {
		let this_ref = this;
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
		this.refreshCamera();
	}

	iterateContainers (fn) {
		let containers = ['map','grid'];
		for (let c of containers) {
			fn(this[c+'_container']);
		}
	}

	refreshCamera () {
		let this_ref = this;
		// move grid
		this.grid_container.x = this.camera[0] % (this.curr_layer.snap[0] * this.zoom);
		this.grid_container.y = this.camera[1] % (this.curr_layer.snap[1] * this.zoom);

		this.map_container.setTransform(this.camera[0], this.camera[1]);//, this.zoom, this.zoom);
		
		this.iterateContainers((cont)=>{
			cont.scale.x = this_ref.zoom;
			cont.scale.y = this_ref.zoom;
		})
		this.drawCrosshair();
		this.drawOrigin();
	}

	drawCrosshair () {
		if (this.curr_layer) {
			var stage_width =  this.game_width;
			var stage_height = this.game_height;

			let center = [
				this.place_mouse[0],
				this.place_mouse[1]
			];
			if (this.obj_type == "object") {
				center = [
					this.half_place_mouse[0],
					this.half_place_mouse[1]
				];
			}

			this.coord_text.x = parseInt((this.game_width - center[0]) / 5 + center[0]);
			this.coord_text.y = parseInt(center[1] + 8);
			this.coord_text.text = 'x '+parseInt(this.mouse[0])+' y '+parseInt(this.mouse[1]);
			if (this.obj_type == "object") {
				this.coord_text.text = 'x '+parseInt(this.half_mouse[0])+' y '+parseInt(this.half_mouse[1]);
			}
			if (this.zoom != 1) 
				this.coord_text.text += ` zoom: ${blanke.places(this.zoom, 2)}`;

			this.obj_info_text.x = parseInt((this.game_width - center[0]) / 5 + center[0]);
			this.obj_info_text.y = parseInt(center[1] + 20);
			this.obj_info_text.text = Object.values(this.obj_info).join('\n');

			// line style
			this.crosshair_graphics.clear()
			this.crosshair_graphics.lineStyle(2, 0xffffff, this.grid_opacity);

			// horizontal
			this.crosshair_graphics.moveTo(0, center[1])
			this.crosshair_graphics.lineTo(stage_width, center[1]);
			// vertical
			this.crosshair_graphics.moveTo(center[0], 0);
			this.crosshair_graphics.lineTo(center[0], stage_height);
		}
	}

	// when object place type selector is changed
	refreshObjectType (new_type) {
		if (new_type) 
			this.el_sel_placetype.value = new_type;

		this.obj_type = this.el_sel_placetype.value;
		this.el_image_sel.classList.add('hidden');
		this.el_image_container.classList.add('hidden');
		this.el_object_container.classList.add('hidden');
		this.el_tag_form.container.classList.add('hidden');		
		
		if (this.obj_type == 'image') {
			this.el_image_sel.classList.remove("hidden");
			if (this.curr_image)
				this.el_image_container.classList.remove('hidden');
		}
		if (this.obj_type == 'object') {
			this.el_object_container.classList.remove('hidden');
		}
		if (this.obj_type == 'tag') {
			this.el_tag_form.container.classList.remove('hidden');
		}
	}

	// refreshes combo box
	refreshLayerList (old_name, new_name) {
		if (this.layers.length == 0)
			this.addLayer();

		let layer_list = this.layers.map(layer => layer.name);
		this.el_layer_list.setItems(layer_list);
		if (this.curr_layer) {
			this.el_layer_list.selectItem(this.curr_layer.name);
			this.setLayer(this.curr_layer.name);
		}
	}

	// refreshes object list items
	refreshObjectList () {
		if (!this.curr_object) {
			// don't show properties if no object selected
			this.el_object_form.container.style.display = "none";	
		} else {
			this.el_object_form.container.style.display = "block";	
		}
	}

	// add all images in project to the search bar
	refreshImageList() {
		var this_ref = this;
		app.removeSearchGroup('scene_image');
		let walker = nwWALK.walk(nwPATH.join(app.project_path,'assets'));
		this.el_image_sel.innerHTML = `<option class="placeholder" value="" disabled ${this.curr_image ? '' : 'selected'}>Select an image</option>`;
		walker.on('file', function(path, stat, next){
			if (stat.isFile() && !stat.name.startsWith(".") && app.findAssetType(stat.name) == 'image') {
				let full_path = nwPATH.join(path, stat.name);
				var img_path = nwPATH.relative(app.project_path,full_path).replace(/assets[/\\]/,'');
				this_ref.el_image_sel.innerHTML += `<option value="${full_path}" ${this_ref.curr_image && this_ref.curr_image.path == img_path ? 'selected' : ''}>${img_path}</option>`;
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

	drawPoly (obj, points, poly) {
		if (!poly) poly = new PIXI.Graphics();
		poly.clear();

		// add polygon points
		let old_color = parseInt(obj.color.replace('#',"0x"), 16);
		let color = obj.color.replace("#","").toRgb();

		if (color.r > 200 && color.g > 200 && color.b > 200) color = parseInt("0xC8C8C8", 16);
		else color = old_color;

		poly.blendMode = PIXI.BLEND_MODES.OVERLAY;
		poly.lineStyle(2, color, .5, 0);
		poly.beginFill(old_color, .1);
		if (points.length == 2) {
			poly.drawRect(
				points[0]-obj.size[0]/2,
				points[1]-obj.size[1]/2,
				obj.size[0],obj.size[1]
			);
		} else {
			for (let p = 0; p < points.length; p+=2) {
				if (p == 0)
					poly.moveTo(points[p], points[p+1]);
				else
					poly.lineTo(points[p], points[p+1]);
			}
			poly.lineTo(points[0], points[1]);
		}
		poly.endFill();
		return poly;
	}

	// get an image to show behind polygon
	drawObjImage (obj, spr, points) {
		if (!spr) spr = new PIXI.Sprite();
		let info = Code.sprites[obj.name];
		if (info) {
			spr.visible = true;
			let tex = PIXI.Texture.from('file://'+info.path);
			spr.texture = tex;

		} else {
			spr.visible = false;
			return spr;
		}
		// change frame
		spr.texture.frame = new PIXI.Rectangle(
			info.offset[0], info.offset[1],
			info.frame_size[0], info.frame_size[1]
		);
		// reposition sprite
		if (points.length > 1) {
			let min_x, min_y;
			for (let p = 0; p < points.length; p += 2) {
				if (min_x == null || min_x > points[p]) min_x = points[p];
				if (min_y == null || min_y > points[p+1]) min_y = points[p+1];
			}
			spr.x = min_x - info.pivot[0];
			spr.y = min_y - info.pivot[1];
		} else {
			spr.x = points[0] - info.pivot[0];
			spr.y = points[1] - info.pivot[1];
		}
		return spr;
	}

	// when user presses enter to finish object
	// also used when loading a file's objects
	placeObject (points, obj_tag) {
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
		let pixi_poly = this.drawPoly(curr_object, points);
		let pixi_image = this.drawObjImage(curr_object, null, points);

		pixi_poly.interactive = true;
		pixi_poly.interactiveChildren = false;
		pixi_poly.on('pointerup', function(e){
			// add tag
			let obj_ref = this_ref.getObjByUUID(e.currentTarget.obj_uuid);
			if (e.data.originalEvent.button == 0 && this_ref.obj_type == 'tag') {
				let tag = this_ref.el_tag_form.getValue("value");
				if (tag) {
					e.target.tag = tag;
					this_ref.obj_info[obj_ref.name] = obj_ref.name+(tag == '' ? '' : " ("+e.target.tag+")");
					this_ref.drawCrosshair();
					this_ref.export();
				}
			}
		});
		pixi_poly.on('rightup', function(e){
			// remove tag
			let obj_ref = this_ref.getObjByUUID(e.currentTarget.obj_uuid);
			if (this_ref.obj_type == 'tag') {
				e.target.tag = '';
				this_ref.obj_info[obj_ref.name] = obj_ref.name;
				this_ref.drawCrosshair();
				this_ref.export();
			}

			// remove from array
			if (!this_ref.placing_object && this_ref.curr_layer && this_ref.obj_type == 'object' && this_ref.curr_object.name == curr_object.name) {
				let del_uuid = e.target.uuid;
				this_ref.iterObjectInLayer(this_ref.curr_layer.uuid, curr_object.name, function(obj){
					if (del_uuid == obj.poly.uuid) {
						obj.image.destroy();
						if (this_ref.obj_info[curr_object.name])
							delete this_ref.obj_info[curr_object.name];
						e.target.destroy();
						return true;
					}
				});
				this_ref.export();
			}
		});
		// add mouse enter/out events
		const polyHover = function (e) {
			let obj_ref = this_ref.getObjByUUID(e.currentTarget.obj_uuid);
			if (obj_ref) {
				if (e.type == "mouseover") {
					if (e.target.tag)
						this_ref.obj_info[obj_ref.name] = obj_ref.name+" ("+e.target.tag+")";
					else
						this_ref.obj_info[obj_ref.name] = obj_ref.name;
				}
				else if (e.type == "mouseout") {
					if (this_ref.obj_info[obj_ref.name])
						delete this_ref.obj_info[obj_ref.name];
				}
			}
		}
		pixi_poly.on('mouseover',polyHover);
		pixi_poly.on('mouseout',polyHover);

		pixi_poly.uuid = guid();
		pixi_poly.obj_uuid = this.curr_object.uuid;
		if (obj_tag)
			pixi_poly.tag = obj_tag;
		
		this.curr_layer.container.addChild(pixi_image)
		this.curr_layer.container.addChild(pixi_poly);

		if (!this.obj_polys[curr_object.uuid]) this.obj_polys[curr_object.uuid] = {};
		if (!this.obj_polys[curr_object.uuid][this.curr_layer.uuid]) this.obj_polys[curr_object.uuid][this.curr_layer.uuid] = [];
		
		this.obj_polys[curr_object.uuid][this.curr_layer.uuid].push({
			poly: pixi_poly,
			image: pixi_image,
			points: points
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

			/*
			let pt_order = this.placing_object.point_order;
			this.placing_object.points.splice(pt_order[pt_order.length-1], 2);
			this.placing_object.point_order.pop();
			*/
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
					points: [],
					point_order: [],
				}
			}

			// calculate snap
			let snapx = this.curr_layer.snap[0] / 2;
			let snapy = this.curr_layer.snap[1] / 2;
			if (this.snap_on) {
				x -= x % snapx;
				y -= y % snapy;
			}

			/* place it in between closest two points (probably wont)
			let pts = this.placing_object.points;
			let closest_i = 0;
			let closest_dist = -1;

			let dist = 0;
			for (let p = 0; p < pts.length; p+=2) {
				if (p == 0)
					dist = Math.hypot(pts[pts.length-2] - x, pts[pts.length-1] - y) + 
						   Math.hypot(pts[p] - x, pts[p+1] - y);
				else
					dist = Math.hypot(pts[p-2] - x, pts[p-1] - y) + 
						   Math.hypot(pts[p] - x, pts[p+1] - y);

				if (dist < closest_dist || closest_dist == -1) {
					closest_dist = dist;
					closest_i = p;
				}
			}

			// add to main shape
			this.placing_object.points.splice(closest_i, 0, y);
			this.placing_object.points.splice(closest_i, 0, x);
			this.placing_object.point_order.push(closest_i);
			*/
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
       		console.error(error);
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
			}
			layer.container.setChildIndex(place_image.pixi_tilemap[layer.uuid], 0);
			bringToFront(place_image.pixi_tilemap[layer.uuid])


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

	deleteTile (x,y) {
		for (let s in this.curr_image.pixi_images) {
			if (this.curr_image.pixi_images[s].layer_name == this.curr_layer.name) {
				let sprite = this.curr_image.pixi_images[s].sprite;
				let rect = sprite.getBounds();
				rect.x -= this.camera[0];
				rect.y -= this.camera[1];
				
				if (rect.contains(x * this.zoom,y * this.zoom)) {
					sprite.destroy();
					delete this.curr_image.pixi_images[s];
					this.redrawTiles();

					this.export();
				}
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
		for (let obj_uuid in this.objects) {
			if (this.objects[obj_uuid].name === name) {
				for (let layer_uuid in this.obj_polys[obj_uuid]) {
					var new_array = [];

					for (let obj in this.obj_polys[obj_uuid][layer_uuid]) {

						let remove_obj = func(this.obj_polys[obj_uuid][layer_uuid][obj]);
						if (!remove_obj) new_array.push(this.obj_polys[obj_uuid][layer_uuid][obj]);
					}
					this.obj_polys[obj_uuid][layer_uuid] = new_array;
				}
				return;
			}
		}
	}

	// return true if object should be removed
	iterObjectInLayer (layer_uuid, name, func) {
		for (let obj_uuid in this.objects) {
			if (this.objects[obj_uuid].name === name) {
				for (let layer_name in this.obj_polys[obj_uuid]) {
					let new_array = [];
					for (let obj in this.obj_polys[obj_uuid][layer_name]) {
						let remove_obj = func(this.obj_polys[obj_uuid][layer_name][obj]);
						if (!remove_obj) new_array.push(this.obj_polys[obj_uuid][layer_name][obj]);
					}
					this.obj_polys[obj_uuid][layer_name] = new_array;
				}
				return;
			}
		}		
	}

	getObjByUUID (uuid) {
		return this.objects[uuid];
	}

	// https://stackoverflow.com/questions/1349404/generate-random-string-characters-in-javascript
	addObject (info) {
		var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%<>?&+=";

		info = info || {};
		ifndef_obj(info, {
			name: null,
			char: possible.charAt(Math.floor(Math.random() * possible.length)),
			color: "#000000",
			size: [this.curr_layer.snap[0], this.curr_layer.snap[1]],
			uuid: guid()
		});

		this.objects[info.uuid] = info;
		this.el_obj_list.addItem(info.name);
		this.el_obj_list.setItemColor(info.name, info.color);
		this.setObject(info.name);
		this.drawDotPreview();

		return info.uuid;
	}

	drawDotPreview () {
		if (!this.dot_preview) {
			this.dot_preview = new PIXI.Graphics();
			this.overlay_container.addChild(this.dot_preview);	
		}

		if (this.obj_type == "object" && this.curr_object) {
			this.dot_preview.clear();
			this.dot_preview.beginFill(parseInt(this.curr_object.color.replace('#',"0x"),16), .75);
			this.dot_preview.drawRect(this.half_place_mouse[0]-2,this.half_place_mouse[1]-2,4,4);
			this.dot_preview.endFill();
		} else {
			this.dot_preview.clear();
		}
	}

	loadObjectsFromSettings() {
		let this_ref = this;
		
		if (app.project_settings.scene && app.project_settings.scene.objects) {
			let last_obj_name = '';
			if (this.curr_object)
				last_obj_name = this.curr_object.name;
			
			this.objects = [];
			let obj_ids = app.project_settings.scene.object_order;
			if (!obj_ids || obj_ids.length == 0) obj_ids = Object.keys(app.project_settings.scene.objects);
			
			for (let uuid of obj_ids) {
				let obj = app.project_settings.scene.objects[uuid];
				if (!obj) continue;

				this.addObject(obj);
				this.iterObject(obj.name, function(i_obj) {
					this_ref.drawPoly(obj, i_obj.points, i_obj.poly);
					this_ref.drawObjImage(obj, i_obj.image, i_obj.points);
				});
			}
			this.setObject(last_obj_name);
		}
	}

	setObject (name) {
		for (let uuid in this.objects) {
			if (this.objects[uuid].name === name) {
				this.curr_object = this.objects[uuid];
				this.el_object_form.setValue('name', this.curr_object.name);
				this.el_object_form.setValue('color', this.curr_object.color);
				this.el_object_form.setValue('size', this.curr_object.size[0], 0);
				this.el_object_form.setValue('size', this.curr_object.size[1], 1);

				this.el_object_form.container.style.display = "block";

				this.iterObjectInLayer (this.curr_layer.uuid, name, function(obj){
					bringToFront(obj.image);
					bringToFront(obj.poly);
				});
			}
		}

		if (this.curr_object) {
			this.el_obj_list.selectItem(this.curr_object.name);
		} else {
			// no object of that name found
			this.el_object_form.container.style.display = "none";	
		}
	}

	deleteObject (uuid) {
		delete app.project_settings.scene.objects[uuid];
		app.project_settings.scene.object_order.splice(app.project_settings.scene.object_order.indexOf(uuid),1);
		delete this.objects[uuid];
		this.export();
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
		let this_ref = this;

		path = app.cleanPath(path);
		let img = this.getImage(path);
		if (img) {
			this_ref.loadImageTexture(img, function(){
				// set image inputs
				if (img.snap[0] > img.texture.width) img.snap[0] = img.texture.width;
				if (img.snap[1] > img.texture.height) img.snap[1] = img.texture.height;
				for (var property of ['snap','offset', 'spacing']) {
					this_ref.el_image_form.setValue(property, img[property][0], 0);
					this_ref.el_image_form.setValue(property, img[property][1], 1);
				}
				this_ref.el_image_form.setValue('align', img.align || "top-left");

				if (onReady) onReady(img);
			});
			
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
		
		info = info || {};
		ifndef_obj(info, {
			name: layer_name,
			depth: 0,
			offset: [0, 0],
			snap: [32, 32],
			uuid: guid()
		});

		info.snap = info.snap.map(Number);

		info.container = new PIXI.Container();
		this.map_container.addChild(info.container);
		this.layers.push(info);
		this.el_layer_list.addItem(info.name);
		this.setLayer(info.name);

		return info.name;
	}

	removeLayer (name) {
		let layer_index = 0;
		for (let l = 0; l < this.layers.length; l++) {
			if (this.layers[l].name == name) {
				layer_index = l;
				// remove objects
				this.layers[l].container.destroy();
				// remove images
				for (let obj of this.images) {
					if (obj.pixi_tilemap[this.layers[l].uuid])
						obj.pixi_tilemap[this.layers[l].uuid].destroy();
					for (let key in obj.pixi_images) {
						if (obj.pixi_images[key].layer_name == name)
							delete obj.pixi_images[key];
					}
				}
				this.layers.splice(l,1);
			}
		}
		this.el_layer_list.removeItem(name,true);
		if (this.layers.length > 0) {
			this.curr_layer = this.layers[Math.max(layer_index-1,0)];
		}
		this.refreshLayerList();
		this.export();
	}

	getLayer (name, is_uuid) {
		for (var l = 0; l < this.layers.length; l++) {
			if ((is_uuid && this.layers[l].uuid == name) || this.layers[l].name === name) 
				return this.layers[l];
		}
	}

	setLayer (name, is_uuid) {
		for (var l = 0; l < this.layers.length; l++) {
			if ((is_uuid && this.layers[l].uuid == name) || this.layers[l].name == name) {
				this.curr_layer = this.layers[l];
				this.el_layer_form.setValue('name', this.curr_layer.name);
				this.el_layer_form.setValue('snap', this.curr_layer.snap[0], 0);
				this.el_layer_form.setValue('snap', this.curr_layer.snap[1], 1);
								
				this.el_layer_list.selectItem(name);
			}
		}
		this.refreshLayers()
		this.drawGrid();
	}

	refreshLayers () {
		let this_ref = this;
		this.el_layer_list.getItems().reverse().forEach((o,i)=>{
			let layer = this_ref.getLayer(o);
			layer.container.alpha = 0.25;
			this_ref.map_container.setChildIndex(layer.container, i);
		});
		if (this.curr_layer) {
			//this.map_container.setChildIndex(this.curr_layer.container, this.map_container.children.length-1);
			this.curr_layer.container.alpha = 1;
		}
	}

	load (file_path) {
		let this_ref = this;

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
				var full_path = nwPATH.normalize(nwPATH.join(app.project_path,img.path));
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

			this.loadObjectsFromSettings();

			// objects
			for (let obj_uuid in this.objects) {
				var obj = this.objects[obj_uuid];
				this.setObject(obj.name);

				for (var layer_name in data.objects[obj.uuid]) {
					this.setLayer(layer_name, true);
					for (var c = 0; c < data.objects[obj.uuid][layer_name].length; c++) {
						let obj_points = data.objects[obj.uuid][layer_name][c];
						this.placeObject(obj_points.slice(1), obj_points[0]);
					}
				}
			}

			// settings
			if (data.settings) {
				this.setLayer(data.settings.last_active_layer);
				this.refreshObjectType(data.settings.last_object_type);
				this.setObject(data.settings.last_object_name);
				this.setCameraPosition(data.settings.camera[0], data.settings.camera[1]);
			}
		}
		this.setTitle(nwPATH.basename(file_path));
		this.setOnClick(function(){
			openScene(this_ref.file);
		});
		this.refreshLayerList();
		this.loadObjectsFromSettings();
		this.resizeEditor();
	}

	export () {
		if (this.deleted) return;

		let export_data = {'objects':{}, 'layers':[], 'images':[], 'settings':{
			camera:this.camera,
			last_active_layer:this.curr_layer.name,
			last_object_type:this.obj_type,
			last_object_name:ifndef(this.curr_object, {name:null}).name
		}};
		if (!app.project_settings.scene)
			app.project_settings.scene = {};

		let layer_names = {};
		let layer_uuids = {};

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
			layer_uuids[layer.uuid] = true;
		}

		// objects
		if (!app.project_settings.scene.objects)
			app.project_settings.scene.objects = {};

		app.project_settings.scene.object_order = Object.keys(this.objects);
		for (let obj_uuid in this.objects) {
			let obj = this.objects[obj_uuid];

			// save object info
			app.project_settings.scene.objects[obj_uuid] = obj;

			let polygons = {};

			// save object coordinates
			for (let layer_uuid in this.obj_polys[obj_uuid]) {
				if (layer_uuids[layer_uuid] == true) {
					let polys = this.obj_polys[obj_uuid][layer_uuid];
					if (polys.length > 0) {
						polygons[layer_uuid] = [];
					
						for (let p in polys) {
							polygons[layer_uuid].push(
								[ifndef(polys[p].poly.tag,'')].concat(polys[p].points.slice())
							);
						}
						export_data.objects[obj.uuid] = polygons;
					}
				}
			}
		}

		//images
		let re_img_path = /.*(assets\/.*)/g;
		for (let obj of this.images) {
			let orig_path = app.cleanPath(nwPATH.relative(app.project_path,obj.path))
			let regex_result = orig_path.match(re_img_path);
			let img_path;
			if (regex_result) {
				img_path = regex_result[0];
			} else {
				continue;
			}

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

					if (!exp_img.coords[img.layer_name]) {
						exp_img.coords[img.layer_name] = [];
					}

					exp_img.coords[img.layer_name].push([
						img.x, img.y,
						img.frame.x, img.frame.y, img.frame.width, img.frame.height,
						img.snapped
					]);
				}
			}

			// only save image if it was used
			if (Object.keys(obj.pixi_images).length > 0) {
				export_data.images.push(exp_img);
			}
		}

		if (!(app.error_occured && app.error_occured.error.stack.includes('sceneeditor'))) {
			app.saveSettings();
			nwFS.writeFileSync(this.file, JSON.stringify(export_data));
		} else {
			console.log(this.file+' not saved cause of error',app.error_occured)
			blanke.toast(nwPATH.basename(this.file)+' not saved because an error occurred earlier!</br>Please re-open the IDE :(');
		}
	}

	static refreshSceneList(path) {
		app.removeSearchGroup("Map");
		addScenes(ifndef(path, app.project_path));
	}
}

document.addEventListener('fileChange', function(e){
	if (e.detail.file.includes("maps")) {
		SceneEditor.refreshSceneList();
	}
});

function openScene(file_path) {
	if (!FibWindow.focus(nwPATH.basename(file_path)))
		new SceneEditor(file_path);
}

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
				else if (file.endsWith('.map')) {
					app.addSearchKey({
						key: file,
						onSelect: function(file_path){
							openScene(file_path);
						},
						tags: ['map'],
						args: [full_path],
						category: 'Map',
						group: 'Map'
					});
				}
			});
		});
	});
}

document.addEventListener("closeProject", function(e){	
	app.removeSearchGroup("Scene");
	app.removeSearchGroup("scene_image");
});

let last_new;
document.addEventListener("openProject", function(e){
	var proj_path = e.detail.path;
	SceneEditor.refreshSceneList(proj_path);
	if (!app.project_settings.scene)
		app.project_settings.scene = {};

	app.addSearchKey({
		key: 'Add a map',
		onSelect: function() {
			var map_dir = map_folder();
			// overwrite the file if it exists. fuk it (again)!!
			nwFS.mkdir(map_dir, function(err){
				nwFS.readdir(map_dir, function(err, files){
					let num = files.length;
					while (nwFS.pathExistsSync(nwPATH.join(map_dir, 'map'+num+'.map')))
						num++;
					nwFS.writeFile(nwPATH.join(map_dir, 'map'+num+'.map'),"");
				
					// edit the new script
					app.addPendingQuickAccess('map'+num+'.map');
					new SceneEditor(nwPATH.join(map_dir, 'map'+num+'.map'));
				});
			});	
		},
		tags: ['new']
	});
});