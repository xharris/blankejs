// rework object editor:
// - (DONE) click empty space: add rectangle object
// - (DONE) click on edge of object (point is on edge): add point in between points of edge
// - can drag points (important)

// var earcut = require('./includes/earcut.js');


let map_folder = () => nwPATH.join(app.project_path, "assets", "maps");

class SceneEditor extends Editor {
  constructor(file_path) {
    super();
    this.setupFibWindow(true);

    var this_ref = this;

    this.file = "";

    this.grid_opacity = 0.05;
    this.deleted = false;

    this.obj_type = "";
    this.curr_layer = { snap: [1, 1] };
    this.curr_object = null; // reference from this.objects[]
    this.curr_image = null; // reference from this.images[]
    this.layers = [];
    this.objects = []; // all objects placed on the canvas
    this.obj_polys = {};
    this.obj_paths = {}; // { 'x,y:x,y':PIXI.Graphics }
    this.images = []; // placeable images in project folders {path, snap[x,y], pixi_images{}}

    this.placing_object = false;
    this.dot_preview = null;
    this.image_preview = null;
    this.selected_tiles = [];

    this.game_width = window.innerWidth;
    this.game_height = window.innerHeight;

    this.pixi = new BlankePixi({
      w: this.game_width,
      h: this.game_height,
      zoom_clamp: [0.1, 12],
    });
    this.grid_color = 0xbdbdbd;
    this.appendBackground(this.pixi.view);

    // create map container
    this.overlay_container = new PIXI.Container(); // displayed above everything
    this.map_container = new PIXI.Container();
    this.path_containers = {} // { layer_id:PIXI.Container }

    this.grid_container = new PIXI.Container();
    this.grid_graphics = new PIXI.Graphics(); // position wraps based on layer snap
    this.origin_graphics = new PIXI.Graphics();
    this.crosshair_graphics = new PIXI.Graphics();

    this.obj_info = {}
    this.path_info = {}

    // this.grid_container.addChild(this.origin_graphics);
    this.grid_container.addChild(this.grid_graphics);
    this.overlay_container.addChild(this.origin_graphics);
    this.overlay_container.addChild(this.crosshair_graphics);

    var el_br = app.createElement("br");

    // create sidebar
    this.el_sidebar = app.createElement("div", "sidebar");

    // IMAGE elements
    this.el_image_form = new BlankeForm([
      ["image settings", true],
      ["snap", "number", { inputs: 2, separator: "x" }],
      ["offset", "number", { inputs: 2, separator: "x" }],
      ["spacing", "number", { inputs: 2, separator: "x" }],
      ["align", "select", { choices: ["top-left", "top-right", "bottom-left", "bottom-right"] }],
      ["zoom", "number", { min: 50, max: 150, step: 5, default: 100 }]
    ]);
    this.el_image_sel = app.createElement("select", "image-select");
    this.el_image_info = app.createElement("p", "image-info");
    this.el_image_container = app.createElement("div", "image-container");
    this.el_image_tiles_container = app.createElement(
      "div",
      "image-tiles-container"
    );
    this.el_image_preview = app.createElement("img", "image-preview");
    this.el_image_grid = app.createElement("div", "image-grid");

    this.el_image_container.classList.add("hidden");

    // OBJECT elements
    this.el_object_container = app.createElement("div", "object-container");

    this.el_object_form = new BlankeForm([
      ["name", "text"], //, {'label':false}],
      ["color", "color", { label: false }],
      ["size", "number", { inputs: 2, separator: "x" }],
      ["multi_point", "checkbox", { default: false, label: "multi-point" }],
      ["path_mode", "checkbox", { default: false }]
    ]);
    this.el_object_form.container.style.display = "none";

    this.el_layer_container = blanke.createCollapsible("layer-container", "Layers");
    this.el_snap_container = app.createElement("div", "snap-container");
    this.el_snap_label = app.createElement("p", "snap-label");
    this.el_snap_x = app.createElement("input", "snap-x");
    this.el_snap_y = app.createElement("input", "snap-y");
    this.el_snap_sep = app.createElement("p", "snap-sep");

    this.el_sel_placetype = app.createElement("select", "select-placetype");
    this.el_input_object = app.createElement("input", "input-object");
    // add object types
    let obj_types = ["none", "image", "object", "tag"];
    for (var o = 0; o < obj_types.length; o++) {
      var new_option = app.createElement("option");
      new_option.value = obj_types[o];
      new_option.innerHTML = obj_types[o];
      this.el_sel_placetype.appendChild(new_option);
    }
    this.el_sel_placetype.addEventListener("change", function (e) {
      // populate object selection list
      this_ref.refreshObjectType();
    });

    // IMAGE elements
    this.refreshImageList();
    this.el_image_preview.ondragstart = function () {
      return false;
    };
    this.el_image_sel.addEventListener("change", e => {
      this_ref.setImage(
        e.target.options[e.target.selectedIndex].value,
        function (img) {
          // set current image variable
          this_ref.curr_image = img;
          this_ref.refreshObjectType();
          this_ref.refreshImageGrid();
        }
      );
    });

    this.el_image_form.setValue("snap", 32, 0);
    this.el_image_form.setValue("snap", 32, 1);
    this.el_image_form.onChange("snap", function (value) {
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

    this.el_image_form.setValue("offset", 0, 0);
    this.el_image_form.setValue("offset", 0, 1);
    this.el_image_form.onChange("offset", function (value) {
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

    this.el_image_form.setValue("spacing", 0, 0);
    this.el_image_form.setValue("spacing", 0, 1);
    this.el_image_form.onChange("spacing", function (value) {
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

    this.el_image_form.onChange("align", function (value) {
      if (this_ref.curr_image) {
        this_ref.curr_image.align = value;
      }
    });

    this.el_image_form.onChange("zoom", amt => {
      this.el_image_preview.style.transform = `scale(${amt / 100})`;
      this.el_image_grid.style.transform = `scale(${amt / 100})`;
    })

    this.el_image_grid.ondragstart = function () {
      return false;
    };
    this.selected_image_frames = [];
    this.selected_xmin = -1;
    this.selected_ymin = -1;
    this.selected_width = -1;
    this.selected_height = -1;
    function selectImageTiles(e) {
      if (e.target && e.target.matches("div.cell") && e.buttons != 0) {
        if (e.buttons == 1) {
          // if SHIFT is not held down, clear all other tiles
          if (!e.shiftKey) {
            let el_tiles = document.querySelectorAll(".image-grid div.cell");
            for (let tile of el_tiles) {
              tile.classList.remove("selected");
            }
          }
          e.target.classList.add("selected");
        }
        if (e.buttons == 2) e.target.classList.remove("selected");

        this_ref.refreshImageSelectionList();
      }
      e.preventDefault();
    }
    this.el_image_grid.addEventListener("mousemove", selectImageTiles);
    this.el_image_grid.addEventListener("mousedown", selectImageTiles);
    this.el_image_grid.addEventListener("contextmenu", e => {
      e.preventDefault();
    });

    // OBJECT elements

    // object name
    this.el_object_form.onChange("name", value => {
      value = value.trim();
      if (this.curr_object) {
        if (value == "") return this.curr_object.name;
        else {
          this.renameObject(this.curr_object.uuid, value);
        }
      }
    });

    // object color
    this.el_object_form.onChange("color", value => {
      if (this.curr_object) {
        this.recolorObject(this.curr_object.uuid, value);
      }
    });

    // object size
    this.el_object_form.onChange("size", value =>
      this.setObjectSize(this.curr_object.uuid, value)
    );

    // object path
    this.el_object_form.onChange("path_mode", value => {
      if (value)
        this.refreshObjectPaths()
      else
        this.clearObjectPaths()
    });

    // add object button
    this.el_obj_list = new BlankeListView({
      object_type: "object",
      actions: {
        delete: "remove object",
      },
    });
    this.el_obj_list.onItemAction = (icon, text) => {
      // object deletion
      if (icon == "delete") {
        let obj = this.getObjByName(text);
        if (obj) {
          blanke.showModal(
            "<label>Remove '" +
            obj.name +
            "'?<br/>Objects are global and it will be removed from all maps.</label>",
            {
              yes: () => {
                this.deleteObject(obj.uuid);
              },
              no: () => { },
            }
          );
        }
      }
    };
    this.el_obj_list.onItemSelect = function (text) {
      this_ref.setObject(text);
    };
    this.el_obj_list.onItemAdd = function (text) {
      this_ref.addObject({ name: text });
      this_ref.export();
      return false;
    };
    this.el_obj_list.onItemMoveUp = text => {
      this.objChangeEvent(text, "move_up");
    };
    this.el_obj_list.onItemMoveDown = text => {
      this.objChangeEvent(text, "move_down");
    };
    this.el_obj_list.onItemSwap = (text1, text2) => {
      let obj1, obj2;
      for (let uuid in this.objects) {
        if (this.objects[uuid].name == text1) obj1 = uuid;
        if (this.objects[uuid].name == text2) obj2 = uuid;
      }
      let new_list = {};
      Object.keys(this.objects)
        .map(key => (key == obj1 ? obj2 : key == obj2 ? obj1 : key))
        .forEach(key => {
          new_list[key] = this.objects[key];
        });
      this.objects = new_list;
      this.export();
    };

    this.el_layer_form = new BlankeForm([
      ["name", "text"],
      ["snap", "number", { inputs: 2, separator: "x" }],
    ]);

    this.el_layer_form.setValue("snap", 32, 0);
    this.el_layer_form.setValue("snap", 32, 1);
    this.el_layer_form.onChange("snap", value => {
      var new_x = parseInt(value[0]);
      var new_y = parseInt(value[1]);
      if (new_x <= 0) new_x = this.curr_layer.snap[0];
      this.curr_layer.snap[0] = new_x;
      if (new_y <= 0) new_y = this.curr_layer.snap[1];
      this.curr_layer.snap[1] = new_y;

      this.pixi.snap = this.curr_layer.snap.slice();
      // move grid
      this.grid_container.x = this.pixi.camera[0] % this.curr_layer.snap[0];
      this.grid_container.y = this.pixi.camera[1] % this.curr_layer.snap[1];

      this.iterObjectInLayer(this.curr_layer.uuid, function (obj) {
        obj.style.fontSize = this.curr_layer.snap[1]; // only for y snap change;
        if (obj.snapped) {
          obj.x = obj.grid_x * this.curr_layer.snap[0];
          obj.x = obj.x + this.curr_layer.snap[0] / 2 - obj.width / 2;
          obj.y = obj.grid_y * this.curr_layer.snap[1];
          obj.y = obj.y + this.curr_layer.snap[1] / 2 - obj.height / 2;
        }
      });

      this.drawGrid();
      this.export();
    });

    this.el_layer_form.onChange("name", function (value) {
      if (this_ref.curr_layer) {
        if (value == "") return [this_ref.curr_layer.name];
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
      options: ["add"],
      object_type: "layer",
      actions: {
        delete: "remove layer",
      },
    });
    this.el_layer_list.onItemAction = function (icon, text) {
      if (icon == "delete") {
        blanke.showModal("delete '" + text + "'?", {
          yes: function () {
            this_ref.removeLayer(text);
          },
          no: function () { },
        });
      }
    };
    this.el_layer_list.onItemSelect = function (text) {
      this_ref.setLayer(text);
      this_ref.export();
    };
    this.el_layer_list.onItemAdd = function (text) {
      this_ref.addLayer({ name: text });
      this_ref.export();
      return false;
    };
    this.el_layer_list.onItemSwap = function (text1, text2) {
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
    };

    // hide/show scene menu
    this.el_toggle_sidebar = app.createElement("button", "ui-button-sphere");
    this.el_toggle_sidebar.id = "toggle-scene-sidebar";
    this.el_toggle_sidebar.innerHTML =
      "<i class='mdi mdi-light mdi-page-layout-sidebar-right'></i>";
    this.el_toggle_sidebar.onclick = function () {
      this_ref.el_sidebar.classList.toggle("hidden");
    };

    // TAG
    this.el_tag_form = new BlankeForm([["value", "text", { label: false }]]);
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

    this.el_sidebar.appendChild(this.el_layer_container.element);
    this.el_sidebar.appendChild(this.el_sel_placetype);
    this.el_sidebar.appendChild(this.el_object_container);
    this.el_sidebar.appendChild(this.el_image_sel);
    this.el_sidebar.appendChild(this.el_image_container);
    this.el_sidebar.appendChild(this.el_tag_form.container);

    this.appendChild(this.el_sidebar);
    // this.appendChild(this.el_toggle_sidebar); // commented out for SideWindow changes

    this.tile_start = [0, 0];
    this.scene_graphic = new PIXI.Graphics();
    this.map_container.addChild(this.scene_graphic);

    this.pixi.on("dragStop", (e, info) => {
      let { alt, btn, mouse } = info;
      if (!this.selecting && !alt && btn == 0) {
        // place tiles in a snapped line
        if (this.placeImageReady()) {
          this.clearTileSelection();

          let start_x = this.tile_start[0],
            start_y = this.tile_start[1];
          if (
            mouse[0] == this.tile_start[0] &&
            mouse[1] == this.tile_start[1]
          ) {
            this.placeImage(mouse[0], mouse[1], this.curr_image);
          } else {
            let target_x = mouse[0],
              target_y = mouse[1];

            let snapx = this.curr_layer.snap[0],
              snapy = this.curr_layer.snap[1];

            let dx = Math.floor(Math.abs(target_x - start_x) / snapx) + 1;
            let dy = Math.floor(Math.abs(target_y - start_y) / snapy) + 1;

            let x_sign = Math.sign(target_x - start_x);
            let y_sign = Math.sign(target_y - start_y);

            let tiles = Math.floor(
              Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))
            );

            for (let t = 0; t < tiles; t++) {
              let x = Math.floor((t / tiles) * dx) * x_sign * snapx + start_x,
                y = Math.floor((t / tiles) * dy) * y_sign * snapy + start_y;
              this.placeImage(x, y, this.curr_image);
            }
          }

          this.export();
        }
      }
      if (this.selecting) {
        this.selection_finish = true;
        // tile selection FINISH (making rect)
        let g = this.scene_graphic;
        let a = g.selection_area;

        // selection area big enough to continue?
        if (a[2] <= 0 || a[3] <= 0) {
          this.clearTileSelection();
        } else {
          // click-drag tile selector
          let mouse_start, obj_start;
          let last_dx = 0,
            last_dy = 0;
          g.on("pointerdown", e2 => {
            obj_start = [g.x, g.y];
            mouse_start = [this.pixi.snap_mouse[0], this.pixi.snap_mouse[1]];
            g.dragging = true;
            this.selected_tiles.forEach(tile => {
              tile.old_x = tile.x;
              tile.old_y = tile.y;
            });
          });
          g.on("pointermove", e2 => {
            if (g.dragging) {
              let dx = this.pixi.snap_mouse[0] - mouse_start[0];
              let dy = this.pixi.snap_mouse[1] - mouse_start[1];
              if (dx != last_dx || dy != last_dy) {
                last_dx = dx;
                last_dy = dy;
                g.x = obj_start[0] + dx;
                g.y = obj_start[1] + dy;

                // move tiles
                this.selected_tiles.forEach(tile => {
                  tile.moveTo(tile.old_x + dx, tile.old_y + dy);
                });
              }
            }
          });
          let pointerup = e2 => {
            g.dragging = false;
          };
          g.on("pointerup", pointerup);
          g.on("pointerupoutside", pointerup);
        }
      }
      this.export();
    });

    this.pixi.on("mousePlace", (e, info) => {
      const { mouse, half_mouse } = info;
      this.tile_start = [mouse[0], mouse[1]];
      if (this.obj_type == "object") {
        if (!this.el_object_form.getValue("path_mode"))
          this.placeObjectPoint(half_mouse[0], half_mouse[1]);
      }

      if (this.obj_type == "image") this.pixi.bringToFront(this.scene_graphic);

      //if (!this.selecting)
      //	this.placeImage(mouse[0], mouse[1], this.curr_image);
    });

    this.pixi.on("mouseRemove", (e, info) => {
      if (this.obj_type == "object" && !this.el_object_form.getValue("path_mode")) {
        this.removeObjectPoint();
      }
      if (this.obj_type == "image" && this.curr_image) {
        this.deleteTile(info.mx, info.my);
      }
      if (this.obj_type) this.export();
    });

    this.pixi.on("cameraChange", (e, info) => {
      this.refreshCamera();
    });
    this.pixi.on("zoomChanging", (e, info) => {
      this.drawGrid();
    });
    let old_sel_rect;
    this.pixi.on("mouseMove", (e, info) => {
      this.drawCrosshair();

      if (info.btn == 2 && this.obj_type == "image" && this.curr_image)
        this.deleteTile(info.mx, info.my);

      // making tile selection
      if (
        !info.alt &&
        info.ctrl &&
        info.btn == 0 &&
        ["image"].includes(this.obj_type) &&
        !this.selection_finish
      ) {
        // tile selection START
        this.selecting = true;
        let g = this.scene_graphic;
        if (!g.interactive) {
          g.interactive = true;
          g.buttonMode = true;
        }
        let sel_mouse = [info.snap_mouse[0], info.snap_mouse[1]];
        let x = this.tile_start[0],
          y = this.tile_start[1];
        let w = sel_mouse[0] - this.tile_start[0],
          h = sel_mouse[1] - this.tile_start[1];
        if (w < 0) {
          x = sel_mouse[0];
          w = this.tile_start[0] - sel_mouse[0];
        } else {
          w = sel_mouse[0] - this.tile_start[0] + this.curr_layer.snap[0];
        }
        if (h < 0) {
          y = sel_mouse[1];
          h = this.tile_start[1] - sel_mouse[1];
        } else {
          h = sel_mouse[1] - this.tile_start[1] + this.curr_layer.snap[1];
        }
        g.clear();
        g.selection_area = [x, y, w, h];
        let a = g.selection_area;

        if (h != 0 && w != 0) {
          g.lineStyle(2, app.getThemeColor("ide-accent"), 0.75, 1.5);
          g.beginFill(app.getThemeColor("ide-accent"), 0.25);
          g.drawRoundedRect(x, y, w, h, 2);
          // get all tiles in selection area
          if (old_sel_rect != JSON.stringify(a)) {
            old_sel_rect = JSON.stringify(a);
            this.selected_tiles = this.getTiles(
              a[0] + g.x,
              a[1] + g.y,
              a[2],
              a[3]
            );
            let tile_info = {};
            this.selected_tiles.forEach(tile => {
              if (!tile_info[tile.path]) tile_info[tile.path] = 0;
              tile_info[tile.path]++;
            });
            this.selected_tile_info = "";
            Object.keys(tile_info).forEach(path => {
              this.selected_tile_info += ` - ${app.shortenAsset(path)} (${
                tile_info[path]
                })\n`;
            });
          }
        }
      }

      if (!this.selecting) {
        if (info.btn == 0 && this.placeImageReady()) {
          // placing tiles in a snapped line
          this.scene_graphic.clear();
          this.scene_graphic
            .lineStyle(2, app.getThemeColor("ide-accent"), 0.8)
            .moveTo(this.tile_start[0], this.tile_start[1])
            .lineTo(info.mouse[0], info.mouse[1]);
        }
      }

      this.drawDotPreview();
    });

    this.pixi.on("keyCancel", (e, info) => {
      this.clearTileSelection();
    });

    this.pixi.on("keyDelete", (e, info) => {
      this.deleteTileSelection();
    });

    this.pixi.on("keyFinish", (e, info) => {
      this.finishPlacingObject()
    });

    // moving camera with arrow keys
    document.addEventListener("keydown", e => {
      this.drawCrosshair();
    });

    document.addEventListener("keyup", e => {
      this.drawCrosshair();
    });

    this.pixi.stage.addChild(this.map_container);
    this.pixi.stage.addChild(this.grid_container);
    this.pixi.stage.addChild(this.overlay_container);

    // tab focus
    this.has_focus = true;
    let focus = () => {
      this.refreshImageList();
      this.loadObjectsFromSettings();
      // refresh image aligns
      if (this.curr_object) this.refreshObjImages(this.curr_object.name);
      this.has_focus = true;
    };
    this.addCallback("onFocus", () => focus());
    this.addCallback("onTabFocus", () => focus());
    this.addCallback("onTabLostFocus", function () {
      this_ref.export();
      this_ref.has_focus = false;
    });

    this.obj_type = "object";
    this.refreshObjectType();

    document.addEventListener("fileChange", function (e) {
      if (e.detail.type == "change" && this_ref.has_focus) {
        if (this_ref.curr_image && app.findAssetType(e.detail.file) == "image")
          this_ref.refreshImageList();
      }
    });

    document.addEventListener("code.updateEntity", e => {
      this.refreshObjImages(e.detail.entity_name, e.detail.info);
    });

    document.addEventListener("sceneeditor.objectchanged", e => {
      this.skip_change_event = true;
      if (e.detail.src_file !== this.file) {
        switch (e.detail.action) {
          case "add":
            this.addObject(e.detail.info);
            break;
          case "name":
            this.renameObject(
              e.detail.uuid,
              e.detail.info.new_name,
              e.detail.info.old_name
            );
            break;
          case "color":
            this.recolorObject(e.detail.uuid, e.detail.info.color);
            break;
          case "size":
            this.setObjectSize(e.detail.uuid, e.detail.info.size);
            break;
          case "move_up": // uuid is actually name
            this.el_obj_list.moveItemUp(e.detail.uuid);
            break;
          case "move_down": // uuid is actually name
            this.el_obj_list.moveItemDown(e.detail.uuid);
            break;
          case "delete":
            this.deleteObject(e.detail.uuid);
            break;
        }
      }
      this.skip_change_event = false;
    });

    this.addCallback("onResize", () => {
      this.pixi.resize(() => {
        this.game_width = this.pixi.width;
        this.game_height = this.pixi.height;
        this.drawGrid();
      });
    });

    if (file_path) this.load(file_path);
    else this.loaded = true;
  }

  clearTileSelection() {
    let g = this.scene_graphic;
    g.clear();
    if (this.selecting) {
      // tile selection STOP
      this.selecting = false;
      this.selection_finish = false;
      this.selected_tiles = [];
      this.selected_tile_info = "";
      g.x = 0;
      g.y = 0;
      g.interactive = false;
      g.buttonMode = false;
    }
  }

  deleteTileSelection() {
    if (this.selecting && this.selected_tiles.length > 0) {
      blanke.showModal(
        `<label>Remove selected tiles in this layer? <br/>Selected:<br/><div style="display:inline-block;text-align:left;">${this.selected_tile_info.replace(
          new RegExp("\n", "g"),
          "<br/>"
        )}</div></label>`,
        {
          yes: () => {
            let last_uuid = "";
            let img_ref;
            this.selected_tiles.forEach(tile => {
              if (tile.uuid != last_uuid) {
                for (let img_obj of this.images) {
                  if (img_obj.uuid == tile.uuid) {
                    last_uuid = tile.uuid;
                    img_ref = img_obj;
                  }
                }
              }
              this.deleteTile(tile.x, tile.y, {
                layer_name: tile.layer_name,
                img_ref: img_ref,
                skip_export: true,
              });
              this.clearTileSelection();
            });
            // this.export();
          },
          no: () => { },
        }
      );
    }
  }

  onClose() {
    app.removeSearchGroup("Scene");
    //nwFS.unlink(this.file);
    addScenes(app.project_path);
  }

  drawGrid() {
    if (this.curr_layer) {
      let zoom = this.pixi.zoom;
      var snapx = this.curr_layer.snap[0];
      var snapy = this.curr_layer.snap[1];
      var stage_width = this.game_width / zoom;
      var stage_height = this.game_height / zoom;

      if (!this.grid_graphics) {
        this.grid_graphics = new PIXI.Graphics();
        this.grid_container.addChild(this.grid_graphics);
      }

      this.grid_graphics.clear();
      this.grid_graphics.lineStyle(
        1 / zoom,
        this.grid_color,
        this.grid_opacity
      );
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

  drawOrigin() {
    if (this.curr_layer) {
      var stage_width = this.game_width;
      var stage_height = this.game_height;
      let camera = this.pixi.camera;

      // origin line
      this.origin_graphics.clear();
      this.origin_graphics.lineStyle(1, this.grid_color, 0.25);

      // horizontal
      this.origin_graphics.moveTo(0, camera[1]);
      this.origin_graphics.lineTo(stage_width, camera[1]);
      // vertical
      this.origin_graphics.moveTo(camera[0], 0);
      this.origin_graphics.lineTo(camera[0], stage_height);
    }
  }

  setCameraPosition(x, y) {
    this.pixi.setCameraPosition(x, y);
    this.refreshCamera();
  }

  iterateContainers(fn) {
    let containers = ["map", "grid"];
    for (let c of containers) {
      fn(this[c + "_container"]);
    }
  }

  refreshCamera() {
    let { camera, zoom } = this.pixi;
    // move grid
    this.grid_container.x = camera[0] % (this.curr_layer.snap[0] * zoom);
    this.grid_container.y = camera[1] % (this.curr_layer.snap[1] * zoom);

    this.map_container.setTransform(camera[0], camera[1]); //, zoom, zoom);

    this.iterateContainers(cont => {
      cont.scale.x = zoom;
      cont.scale.y = zoom;
    });
    this.drawCrosshair();
    this.drawOrigin();
    this.drawGrid();
  }

  drawCrosshair() {
    if (this.curr_layer) {
      let mouse = this.pixi.mouse;
      let real_mouse = this.pixi.real_mouse;
      let pmouse = this.pixi.place_mouse;
      let hmouse = this.pixi.half_mouse;
      let hpmouse = this.pixi.half_place_mouse;

      var stage_width = this.game_width;
      var stage_height = this.game_height;

      let info_text = ["x " + parseInt(mouse[0]) + " y " + parseInt(mouse[1])];
      let help_text = [];
      // which mouse coordinates to display
      if (this.obj_type == "object" && !this.el_object_form.getValue("path_mode")) {
        info_text = ["x " + parseInt(hmouse[0]) + " y " + parseInt(hmouse[1])];
      }
      // object being hovered
      let obj_names = Object.values(this.obj_info)
      if (obj_names.length > 0) info_text.push(obj_names.join(", "))
      let path_names = Object.values(this.path_info)
      if (path_names.length > 0) info_text.push(path_names.join(", "))

      if (this.obj_type == "image" && !this.selecting) {
        help_text.push("CtrlClick = select group of tiles")
      }
      // tile selection info
      if (this.selecting) {
        let g = this.scene_graphic;
        let a = g.selection_area;
        if (a)
          info_text.push(`selected x ${a[0] + g.x} y ${a[1] + g.y} w ${a[2]} h ${a[3]}`);
        info_text.push(`\n${this.selected_tile_info}`)
        help_text.push("Drag selection with mouse, Esc = deselect")
      }

      let center = [pmouse[0], pmouse[1]]
      if (this.obj_type == "object") {
        if (this.el_object_form.getValue("path_mode"))
          center = [real_mouse[0], real_mouse[1]]
        else
          center = [hpmouse[0], hpmouse[1]]
      }

      this.pixi.setHelpText(help_text.join('\n'));
      this.pixi.setInfoText(info_text.join('\n'));

      // line style
      this.crosshair_graphics.clear();
      this.crosshair_graphics.lineStyle(2, 0xffffff, this.grid_opacity);

      // horizontal
      this.crosshair_graphics.moveTo(0, center[1]);
      this.crosshair_graphics.lineTo(stage_width, center[1]);
      // vertical
      this.crosshair_graphics.moveTo(center[0], 0);
      this.crosshair_graphics.lineTo(center[0], stage_height);
    }
  }

  // when object place type selector is changed
  refreshObjectType(new_type) {
    if (new_type) this.el_sel_placetype.value = new_type;

    this.obj_type = this.el_sel_placetype.value;
    this.el_image_sel.classList.add("hidden");
    this.el_image_container.classList.add("hidden");
    this.el_object_container.classList.add("hidden");
    this.el_tag_form.container.classList.add("hidden");

    if (this.obj_type == "image") {
      this.el_image_sel.classList.remove("hidden");
      if (this.curr_image) this.el_image_container.classList.remove("hidden");
    }
    if (this.obj_type == "object") {
      this.el_object_container.classList.remove("hidden");
    }
    if (this.obj_type == "tag") {
      this.el_tag_form.container.classList.remove("hidden");
    }
    this.refreshObjectPaths()
    this.export()
  }

  // refreshes combo box
  refreshLayerList(old_name, new_name) {
    if (this.layers.length == 0) this.addLayer();

    let layer_list = this.layers.map(layer => layer.name);
    this.el_layer_list.setItems(layer_list);
    if (this.curr_layer) {
      this.el_layer_list.selectItem(this.curr_layer.name);
      this.setLayer(this.curr_layer.name);
    }
    this.pixi.snap = this.curr_layer.snap.slice();
  }

  // refreshes object list items
  refreshObjectList() {
    if (!this.curr_object) {
      // don't show properties if no object selected
      this.el_object_form.container.style.display = "none";
    } else {
      this.el_object_form.container.style.display = "block";
    }
  }

  // add all images in project to the search bar
  refreshImageList() {
    let sel_str = `<option class="placeholder" value="" disabled ${
      this.curr_image ? "" : "selected"
      }>Select an image</option>`;
    this.el_image_sel.innerHTML = sel_str;
    app.getAssets("image", files => {
      files.forEach(f => {
        var img_path = app.shortenAsset(f);
        sel_str += `<option value="${f}" ${
          this.curr_image && this.curr_image.path == img_path ? "selected" : ""
          }>${img_path}</option>`;
      });
      this.el_image_sel.innerHTML = sel_str;
    });
  }

  // list of grid cells selected
  refreshImageSelectionList() {
    this.selected_xmin = -1;
    this.selected_ymin = -1;
    this.selected_width = -1;
    this.selected_height = -1;
    this.selected_image_frames = [];

    var el_image_frames = document.querySelectorAll(
      ".image-grid > .cell.selected"
    );
    let max_x = -1;
    let max_y = -1;
    if (el_image_frames) {
      for (var frame of el_image_frames) {
        let x = parseInt(frame.style.left);
        let y = parseInt(frame.style.top);
        let width = parseInt(frame.style.width);
        let height = parseInt(frame.style.height);

        this.selected_image_frames.push({
          x: x,
          y: y,
          width: width,
          height: height,
        });

        if (this.selected_xmin == -1 || x < this.selected_xmin)
          this.selected_xmin = x;
        if (this.selected_ymin == -1 || y < this.selected_ymin)
          this.selected_ymin = y;

        if (x - this.selected_xmin + this.curr_image.snap[0] > this.selected_width)
          this.selected_width = x - this.selected_xmin + this.curr_image.snap[0];
        if (y - this.selected_ymin + this.curr_image.snap[1] > this.selected_height)
          this.selected_height = y - this.selected_ymin + this.curr_image.snap[1];
      }
    }
  }

  placeImageReady() {
    return (
      this.obj_type == "image" &&
      this.curr_image &&
      this.selected_image_frames.length > 0
    );
  }

  refreshImageGrid() {
    if (this.curr_image) {
      // update image info text
      this.el_image_info.innerHTML =
        app.getRelativePath(this.curr_image.path) +
        "<br/>" +
        this.curr_image.texture.width +
        " x " +
        this.curr_image.texture.height;
      this.el_image_info.title = app.getRelativePath(this.curr_image.path);
      this.el_image_preview.src = "file://" + this.curr_image.path;

      var img_width = parseInt(this.el_image_preview.width);
      var img_height = parseInt(this.el_image_preview.height);
      var grid_w = this.curr_image.snap[0];
      var grid_h = this.curr_image.snap[1];

      var str_table = "";
      if (grid_w > 2 && grid_h > 2) {
        let rows =
          Math.ceil(img_height / grid_h) *
          (this.curr_image.spacing[1] > 0 ? this.curr_image.spacing[1] : 1);
        let columns =
          Math.ceil(img_width / grid_w) *
          (this.curr_image.spacing[0] > 0 ? this.curr_image.spacing[0] : 1);

        for (var gy = 0; gy < rows; gy += 1) {
          let y =
            gy * this.curr_image.spacing[1] +
            gy * grid_h +
            this.curr_image.offset[1];
          for (var gx = 0; gx < columns; gx += 1) {
            let x =
              gx * this.curr_image.spacing[0] +
              gx * grid_w +
              this.curr_image.offset[0];
            str_table +=
              "<div class='cell' style='top:" +
              y +
              "px;left:" +
              x +
              "px;width:" +
              grid_w +
              "px;height:" +
              grid_h +
              "px'></div>";
          }
        }
      }
      this.el_image_grid.innerHTML = str_table;
      this.el_image_grid.style.width =
        Math.ceil(img_width / grid_w) * grid_w + "px";
      this.el_image_grid.style.height =
        Math.ceil(img_height / grid_h) * grid_h + "px";

      this.export();
    }
  }

  drawPoly(obj, points, poly) {
    if (!poly) poly = new PIXI.Graphics();
    poly.clear();

    // add polygon points
    let old_color = parseInt(obj.color.replace("#", "0x"), 16);
    let color = obj.color.replace("#", "").toRgb();

    if (color.r > 200 && color.g > 200 && color.b > 200)
      color = parseInt("0xC8C8C8", 16);
    else color = old_color;

    var x = 0, y = 0

    poly.blendMode = PIXI.BLEND_MODES.OVERLAY;
    poly.lineStyle(2, color, 0.5, 0);
    poly.beginFill(old_color, 0.1);
    if (points.length == 2) {
      poly.drawRect(
        points[0] - obj.size[0] / 2,
        points[1] - obj.size[1] / 2,
        obj.size[0],
        obj.size[1]
      );
      poly.drawRect(
        points[0], points[1],
        1, 1
      )
      x = points[0]
      y = points[1]
    } else {
      for (let p = 0; p < points.length; p += 2) {
        if (p == 0) poly.moveTo(points[p], points[p + 1]);
        else poly.lineTo(points[p], points[p + 1]);

        x += points[p]
        y += points[p + 1]
      }
      x /= points.length / 2
      y /= points.length / 2
      poly.lineTo(points[0], points[1]);
    }
    poly.center = [x, y]
    poly.endFill();
    return poly;
  }

  refreshObjImages(name, info) {
    this.iterObject(name, obj => {
      obj.name = name;
      this.drawObjImage(obj, {
        sprite: obj.image,
        points: obj.points,
        info: info,
        poly: obj.poly
      })
    });
  }

  // get an image to show behind polygon
  async drawObjImage(obj, options) {
    var { sprite, points, info, poly } = options

    if (!sprite) sprite = new PIXI.Sprite()
    if (!info) info = Code.sprites[obj.name]

    return new Promise((res, rej) => {
      if (info) {
        sprite.visible = true;
        let img = new Image();
        img.onload = () => {
          let base = new PIXI.BaseTexture(img);
          let tex = new PIXI.Texture(base); // return you the texture
          sprite.texture = tex;

          res(sprite);
        }
        img.src = "file://" + info.path;
      } else {
        res(sprite);
      }
    })
      .then(() => {
        // does frame fit inside base Texture dimensions?
        if (
          !sprite.texture || !info ||
          info.offset[0] + info.frame_size[0] > sprite.texture.width ||
          info.offset[1] + info.frame_size[1] > sprite.texture.height
        ) {
          sprite.visible = false;
        } else {
          sprite.texture.frame = new PIXI.Rectangle(
            info.offset[0],
            info.offset[1],
            info.frame_size[0],
            info.frame_size[1]
          );
        }

        // reposition spriteite
        if (points.length > 1) {
          let min_x, min_y;
          for (let p = 0; p < points.length; p += 2) {
            if (min_x == null || min_x > points[p]) min_x = points[p];
            if (min_y == null || min_y > points[p + 1]) min_y = points[p + 1];
          }
          if (info && info.pivot) {
            sprite.x = min_x - info.pivot[0];
            sprite.y = min_y - info.pivot[1];
          }
        } else {
          if (info && info.pivot) {
            sprite.x = points[0] - info.pivot[0];
            sprite.y = points[1] - info.pivot[1];
          }
        }

        if (poly && poly.text)
          this.pixi.bringToFront(poly.text)

        return sprite;
      })
      .catch(e => console.error(e))
  }

  // when user presses enter to finish object
  // also used when loading a file's objects
  placeObject(points, obj_tag, layer_uuid) {
    const add_to_layer = layer_uuid ? this.getLayer(layer_uuid, true) : this.curr_layer;

    if (points.length > 2) {
      // make sure points don't form a straight line
      let slope_changes = 0;
      let slope = null;
      for (let p = 2; p < points.length; p += 2) {
        let x1 = points[p - 2],
          y1 = points[p - 1];
        let x2 = points[p],
          y2 = points[p + 1];

        let new_slope = (y2 - y1) / (x2 - x1);

        if (new_slope != slope) {
          if (slope !== null) slope_changes++;
          slope = new_slope;
        }
      }
      if (slope_changes == 0) return; // REJECTED!!
    }

    let curr_object = this.curr_object;
    let pixi_poly = this.drawPoly(curr_object, points);

    pixi_poly.interactive = true;
    pixi_poly.interactiveChildren = false;
    pixi_poly.on("pointerup", (e) => {
      // add tag
      if (e.data.originalEvent.button == 0 && this.obj_type == "tag") {
        let tag = this.el_tag_form.getValue("value");
        this.setObjTag(e.target, tag)
      }
    });
    pixi_poly.on("rightup", (e) => {
      // remove tag
      if (this.obj_type == "tag")
        this.setObjTag(e.target)

      // remove from array
      if (
        !this.placing_object &&
        this.curr_layer &&
        this.obj_type == "object" &&
        !this.el_object_form.getValue("path_mode") &&
        this.curr_object.name === curr_object.name &&
        this.curr_layer.uuid === e.target.layer_uuid
      ) {
        let del_uuid = e.target.uuid;
        this.iterObjectInLayer(
          this.curr_layer.uuid,
          curr_object.name,
          (obj) => {
            if (del_uuid == obj.poly.uuid) {
              obj.image.destroy();
              if (this.obj_info[curr_object.name])
                delete this.obj_info[curr_object.name];
              e.target.destroy();
              this.refreshObjectPaths()
              return true;
            }
          }
        );
        this.export();
      }
    });
    // add mouse enter/out events
    const polyHover = (e) => {
      let obj_ref = this.getObjByUUID(e.currentTarget.obj_uuid);
      if (obj_ref && e.currentTarget.layer_uuid == this.curr_layer.uuid) {
        if (e.type == "mouseover") {
          if (e.target.tag)
            this.obj_info[obj_ref.name] =
              obj_ref.name + " (" + e.target.tag + ")";
          else this.obj_info[obj_ref.name] = obj_ref.name;
        } else if (e.type == "mouseout") {
          if (this.obj_info[obj_ref.name])
            delete this.obj_info[obj_ref.name];
        }
      }
    };
    pixi_poly.on("mouseover", polyHover);
    pixi_poly.on("mouseout", polyHover);

    pixi_poly.uuid = guid();
    pixi_poly.obj_uuid = this.curr_object.uuid;
    pixi_poly.layer_uuid = this.curr_layer.uuid;
    if (obj_tag)
      this.setObjTag(pixi_poly, obj_tag)

    this.drawObjImage(curr_object, { points, poly: pixi_poly }).then(pixi_image => {
      pixi_poly.addChild(pixi_image)
      if (pixi_poly.text)
        this.pixi.bringToFront(pixi_poly.text)
      this.obj_polys[curr_object.uuid][add_to_layer.uuid].push({
        poly: pixi_poly,
        image: pixi_image,
        points: points,
      });

      this.export()
    })
    add_to_layer.container.addChild(pixi_poly);

    if (!this.obj_polys[curr_object.uuid])
      this.obj_polys[curr_object.uuid] = {};
    if (!this.obj_polys[curr_object.uuid][add_to_layer.uuid])
      this.obj_polys[curr_object.uuid][add_to_layer.uuid] = [];
  }

  setObjTag(pixi_poly, tag) {
    if (!tag) tag = ""
    const obj_ref = this.getObjByUUID(pixi_poly.obj_uuid);
    if (!pixi_poly.text) {
      pixi_poly.text = this.pixi.getBitmapText()
      pixi_poly.addChild(pixi_poly.text)
    }
    pixi_poly.tag = tag;

    pixi_poly.text.text = tag
    pixi_poly.text.anchor.set(0.5, 0);
    pixi_poly.text.x = pixi_poly.center[0]
    pixi_poly.text.y = pixi_poly.center[1]
    this.pixi.bringToFront(pixi_poly.text)

    this.obj_info[obj_ref.name] = (tag == "") ? obj_ref.name : obj_ref.name + " (" + pixi_poly.tag + ")"

    this.export()
  }

  clearPlacingObject() {
    if (!this.placing_object) return;

    this.placing_object.graphic.destroy();
    for (let g_dot of this.placing_object.graphic_dots) {
      g_dot.destroy();
    }
    this.placing_object = null;
  }

  removeObjectPoint() {
    if (this.placing_object) {
      /*
			let pt_order = this.placing_object.point_order;
			this.placing_object.points.splice(pt_order[pt_order.length-1], 2);
			this.placing_object.point_order.pop();
			*/
      this.placing_object.points.pop();
      this.placing_object.points.pop();

      this.redrawPlacingObject();

      if (this.placing_object.points.length < 2) this.clearPlacingObject();
    }
  }

  parseObjectColor(obj) {
    return parseInt(obj.color.replace("#", "0x"), 16)
  }

  redrawPlacingObject() {
    // redraw polygon
    this.placing_object.graphic.clear();
    this.placing_object.graphic.beginFill(
      this.parseObjectColor(this.curr_object),
      0.5
    );
    this.placing_object.graphic_dots.map(obj => obj.destroy());
    this.placing_object.graphic_dots = [];

    let vertices = this.placing_object.points; //earcut(this.placing_object.points, null, 2);

    let avgx = 0;
    let avgy = 0;
    for (let p = 0; p < vertices.length; p += 2) {
      let ptx = vertices[p];
      let pty = vertices[p + 1];
      avgx += ptx;
      avgy += pty;

      if (p == 0) this.placing_object.graphic.moveTo(ptx, pty);
      else this.placing_object.graphic.lineTo(ptx, pty);

      // add dot to show point
      let new_graphic = new PIXI.Graphics();
      new_graphic.beginFill(
        parseInt(this.curr_object.color.replace("#", "0x"), 16),
        0.75
      );
      new_graphic.drawRect(ptx - 2, pty - 2, 4, 4);
      new_graphic.endFill();
      this.curr_layer.container.addChild(new_graphic);
      this.placing_object.graphic_dots.push(new_graphic);
    }
    if (vertices.length > 2) {
      avgx /= vertices.length / 2;
      avgy /= vertices.length / 2;
    }
    this.placing_object.graphic.endFill();

    this.curr_layer.container.addChild(this.placing_object.graphic);
  }

  finishPlacingObject() {
    if (this.obj_type == "object" && !this.el_object_form.getValue("path_mode") && this.placing_object) {
      this.placeObject(this.placing_object.points.slice());
      this.clearPlacingObject();
      this.export();
    }
  }

  placeObjectPoint(x, y) {
    var curr_object = this.curr_object;

    if (curr_object && this.curr_layer) {
      // place a vertex
      if (!this.placing_object) {
        // first vertex
        this.placing_object = {
          graphic: new PIXI.Graphics(),
          graphic_dots: [], // add later
          points: [],
          point_order: [],
        };
      }

      // calculate snap
      let snapx = this.curr_layer.snap[0] / 2;
      let snapy = this.curr_layer.snap[1] / 2;
      if (this.pixi.snap_on) {
        x -= x % snapx;
        y -= y % snapy;
      }

      this.placing_object.points.push(x, y);

      this.redrawPlacingObject();

      if (this.el_object_form.getValue("multi_point") == false)
        this.finishPlacingObject()
    }
  }

  hashTilePosition(x, y, layer_uuid) {
    return (
      Math.floor(x).toString() +
      "," +
      Math.floor(y).toString() +
      "." +
      layer_uuid
    );
  }

  getTiles(x, y, w, h, layer) {
    if (!layer) layer = this.curr_layer;
    let tile_sprites = [];
    for (let obj of this.images) {
      for (let t in obj.pixi_images) {
        let img = obj.pixi_images[t];
        if (
          img.layer_name == layer.name &&
          img.x + img.frame.width > x &&
          img.y + img.frame.height > y &&
          img.x < x + w &&
          img.y < y + h
        ) {
          tile_sprites.push(img);
        }
      }
    }
    for (let gx = x; gx <= w; gx += layer.snap[0]) {
      for (let gy = y; gy <= h; gy += layer.snap[1]) { }
    }
    return tile_sprites;
  }

  placeImageFrame(x, y, frame, img_ref, layer, from_load) {
    if (!layer) layer = this.curr_layer;
    let place_image = img_ref;

    let new_tile_texture;

    try {
      if (
        frame.x + frame.width <= place_image.texture.width &&
        frame.y + frame.height <= place_image.texture.height
      ) {
        new_tile_texture = new PIXI.Texture(
          place_image.texture,
          new PIXI.Rectangle(frame.x, frame.y, frame.width, frame.height)
        );
        new_tile_texture.layer_uuid = layer.uuid;
      }
    } catch (error) {
      console.error(error);
      blanke.toast("Error loading '" + img_ref.path + "'");
    }

    if (!new_tile_texture) return;

    let new_tile = { x: 0, y: 0, w: 0, h: 0, snapped: false };

    if (!from_load) {
      let offx = 0,
        offy = 0;
      // if (x - this.camera[0] < 0) offx = layer.snap[0];
      // if (y - this.camera[1] < 0) offy = layer.snap[1];

      x += frame.x - this.selected_xmin;
      y += frame.y - this.selected_ymin;

      let align = place_image.align || "top-left";

      if (this.pixi.snap_on && !from_load) {
        x -= x % layer.snap[0];
        y -= y % layer.snap[1];
        new_tile.snapped = true;
      }
      if (align.includes("right")) x -= this.selected_width;
      if (align.includes("bottom")) y -= this.selected_height;
    }

    let text_key = this.hashTilePosition(x, y, layer.uuid);

    // add if a tile isn't already there
    if (from_load || !place_image.pixi_images[text_key]) {
      if (!place_image.pixi_tilemap[layer.uuid]) {
        place_image.pixi_tilemap[layer.uuid] = new PIXI.Container();
        layer.container.addChild(place_image.pixi_tilemap[layer.uuid]);
      }
      layer.container.setChildIndex(place_image.pixi_tilemap[layer.uuid], 0);
      this.pixi.bringToFront(place_image.pixi_tilemap[layer.uuid]);

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
      new_tile.path = place_image.path;

      new_tile.uuid = place_image.uuid;
      new_tile.text_key = text_key;
      new_tile.layer_name = layer.name;
      new_tile.layer_uuid = layer.uuid;
      place_image.pixi_images[text_key] = new_tile;

      new_tile.moveTo = (x, y) => {
        new_tile.x = x;
        new_tile.y = y;
        new_tile.sprite.x = x;
        new_tile.sprite.y = y;
      };
    }
  }

  // aka placeTile
  placeImage(x, y, img_ref, layer) {
    if (this.curr_image && this.curr_layer) {
      for (var frame of this.selected_image_frames) {
        this.placeImageFrame(x, y, frame, img_ref, layer);
      }
    }
  }

  deleteTile(x, y, opt) {
    opt = Object.assign(
      {
        layer_name: this.curr_layer.name,
        img_ref: this.curr_image,
        skip_export: false,
      },
      opt || {}
    );
    for (let s in opt.img_ref.pixi_images) {
      if (opt.img_ref.pixi_images[s].layer_name == opt.layer_name) {
        let sprite = opt.img_ref.pixi_images[s].sprite;
        let rect = sprite.getBounds();
        rect.x -= this.pixi.camera[0];
        rect.y -= this.pixi.camera[1];

        if (rect.contains(x * this.pixi.zoom, y * this.pixi.zoom)) {
          sprite.destroy();
          delete opt.img_ref.pixi_images[s];
          this.redrawTiles();

          if (!opt.skip_export) this.export();
        }
      }
    }
  }

  // uses curr_image and curr_layer
  redrawTiles() {
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
  iterObject(name, func) {
    for (let obj_uuid in this.objects) {
      if (this.objects[obj_uuid].name === name) {
        for (let layer_uuid in this.obj_polys[obj_uuid]) {
          var new_array = [];

          for (let obj in this.obj_polys[obj_uuid][layer_uuid]) {
            let remove_obj = func(this.obj_polys[obj_uuid][layer_uuid][obj]);
            if (!remove_obj)
              new_array.push(this.obj_polys[obj_uuid][layer_uuid][obj]);
          }
          this.obj_polys[obj_uuid][layer_uuid] = new_array;
        }
        return;
      }
    }
  }

  // return true if object should be removed
  iterObjectInLayer(layer_uuid, name, func) {
    for (let obj_uuid in this.objects) {
      if (
        (name === true || this.objects[obj_uuid].name === name) &&
        this.obj_polys[obj_uuid]
      ) {
        if (this.obj_polys[obj_uuid][layer_uuid]) {
          let new_array = [];
          for (let obj in this.obj_polys[obj_uuid][layer_uuid]) {
            let remove_obj = func(this.obj_polys[obj_uuid][layer_uuid][obj]);
            if (!remove_obj)
              new_array.push(this.obj_polys[obj_uuid][layer_uuid][obj]);
          }
          this.obj_polys[obj_uuid][layer_uuid] = new_array;
        }
        return;
      }
    }
  }

  setBoldPath(g, obj1, obj2, obj_info) {
    const [x1, y1] = obj1
    const [x2, y2] = obj2

    g.clear()
    g.lineStyle(5, this.parseObjectColor(obj_info), 0.25)
    g.moveTo(x1, y1)
    g.lineTo(x2, y2)
    g.lineStyle(1, this.parseObjectColor(obj_info), 0.5)
    g.moveTo(x1, y1)
    g.lineTo(x2, y2)

  }

  setWeakPath(g, obj1, obj2, obj_info) {
    const [x1, y1] = obj1
    const [x2, y2] = obj2

    g.clear()
    g.lineStyle(5, this.parseObjectColor(obj_info), 0.05)
    g.moveTo(x1, y1)
    g.lineTo(x2, y2)
    g.lineStyle(1, this.parseObjectColor(obj_info), 0.5)
    g.moveTo(x1, y1)
    g.lineTo(x2, y2)

  }

  addPathGInfo(g) {
    if (g.name) {
      this.path_info[g.name] = g.name
      if (g.tag)
        this.path_info[g.name] =
          g.name + (tag == "" ? "" : " (" + g.tag + ")");
    }
  }

  removePathGInfo(g) {
    if (g.name)
      delete this.path_info[g.name]
  }

  clearObjectPaths() {
    Object.values(this.path_containers).forEach(container => {
      const destroy_arr = []
      container.children.forEach(child => {
        if (!this.obj_paths[child.path_key])
          destroy_arr.push(child)
      })
      destroy_arr.forEach(child => child.destroy())
    })
  }

  addObjectPath(x1, y1, x2, y2, obj_uuid, layer_uuid, load_info) {
    const layer = this.getLayer(layer_uuid, true)

    // create path container for layer
    if (!this.path_containers[layer_uuid]) {
      this.path_containers[layer_uuid] = new PIXI.Container()
      layer.container.addChild(this.path_containers[layer_uuid])
    }

    const path_container = this.path_containers[layer_uuid]

    const uuid1 = [x1, y1].join(',')
    const uuid2 = [x2, y2].join(',')
    const obj1_pts = [x1, y1]
    const obj2_pts = [x2, y2]

    const path_key = [uuid1, uuid2].join(':')

    const setTag = (g, tag) => {
      g.tag = tag
      if (typeof tag == "string") {
        if (!g.text)
          g.text = this.pixi.getBitmapText()
        g.text.text = tag
        g.text.anchor.set(0.5, 1);
        g.text.x = (x1 + x2) / 2
        g.text.y = (y1 + y2) / 2
        g.addChild(g.text)
      }
      this.addPathGInfo(g)
    }
    const activatePath = (g) => {
      if (!this.obj_paths[[uuid1, uuid2].join(':')] && !this.obj_paths[[uuid2, uuid1].join(':')]) {
        this.obj_paths[g.path_key] = g
        this.setBoldPath(g, obj1_pts, obj2_pts, g.object)
        return true
      }
    }

    if (!this.obj_paths[path_key]) {
      // create line from obj1 to obj2
      const g = new PIXI.Graphics()
      g.interactive = true
      g.interactiveChildren = false

      g.path_key = path_key
      g.object = this.getObjByUUID(obj_uuid)
      g.layer_uuid = layer_uuid

      if (load_info) {
        setTag(g, load_info.tag)
        activatePath(g)
      } else {
        this.setWeakPath(g, obj1_pts, obj2_pts, g.object)
      }

      const m = -5

      const xsign = Math.sign(x1 - x2) == 0 ? 1 : Math.sign(x1 - x2)
      const ysign = Math.sign(y1 - y2) == 0 ? 1 : Math.sign(y1 - y2)

      g.hitArea = new PIXI.Polygon([
        x1 + (m * xsign), y1,
        x1, y1 + (m * ysign),
        x2 - (m * xsign), y2,
        x2, y2 - (m * ysign)
      ])

      g.on('mouseover', e => {
        if (!this.obj_paths[g.path_key])
          this.setBoldPath(g, obj1_pts, obj2_pts, g.object)
        this.addPathGInfo(g)
      })

      g.on('mouseout', e => {
        if (!this.obj_paths[g.path_key])
          this.setWeakPath(g, obj1_pts, obj2_pts, g.object)
        this.removePathGInfo(g)
      })

      g.on('pointerdown', e => {
        if (!(this.el_object_form.getValue("path_mode") || this.obj_type == "tag")) return;

        if (this.obj_type == "tag") {
          setTag(g, this.el_tag_form.getValue("value"))

        } else {
          if (!activatePath(g)) {
            delete this.obj_paths[[uuid1, uuid2].join(':')]
            delete this.obj_paths[[uuid2, uuid1].join(':')]
            this.setWeakPath(g, obj1_pts, obj2_pts, g.object)
          }
        }
        this.export();
      })

      g.on('rightup', e => {
        if (this.obj_type == "tag")
          g.tag = ""
        this.export();
      })

      path_container.addChild(g)
    }
  }

  refreshObjectPaths() {
    const layer = this.curr_layer
    const object = this.curr_object

    this.clearObjectPaths()

    if (!this.el_object_form.getValue("path_mode") || this.obj_type != "object" || !this.curr_object) return;
    var object_list = []
    if (this.obj_polys[object.uuid] && this.obj_polys[object.uuid][this.curr_layer.uuid])
      object_list = this.obj_polys[object.uuid][layer.uuid]

    const paths_drawn = {}

    // create a path between all objects
    object_list.forEach(obj1 => {
      object_list.forEach(obj2 => {

        const [x1, y1] = obj1.points
        const [x2, y2] = obj2.points

        const uuid1 = [x1, y1].join(',')
        const uuid2 = [x2, y2].join(',')

        if (uuid1 !== uuid2 && !paths_drawn[`${uuid1},${uuid2}`] && !paths_drawn[`${uuid2},${uuid1}`]) {
          paths_drawn[`${uuid1},${uuid2}`] = true

          this.addObjectPath(
            x1, y1, x2, y2,
            object.uuid, layer.uuid
          )
        }
      })
    })
  }

  getObjByUUID(uuid) {
    return this.objects[uuid];
  }

  getObjByName(name) {
    for (let obj_uuid in this.objects) {
      if (this.objects[obj_uuid].name === name) return this.objects[obj_uuid];
    }
  }

  // https://stackoverflow.com/questions/1349404/generate-random-string-characters-in-javascript
  addObject(info) {
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%<>?&+=";

    info = ifndef_obj(info || {}, {
      name: null,
      char: possible.charAt(Math.floor(Math.random() * possible.length)),
      color: "#000000",
      size: [this.curr_layer.snap[0], this.curr_layer.snap[1]],
      uuid: guid(),
    });

    this.objects[info.uuid] = info;
    this.el_obj_list.addItem(info.name);
    this.el_obj_list.setItemColor(info.name, info.color);
    this.setObject(info.name);
    this.drawDotPreview();

    this.objChangeEvent(info.uuid, "add", info);

    return info.uuid;
  }

  drawDotPreview() {
    if (!this.dot_preview) {
      this.dot_preview = new PIXI.Graphics();
      this.overlay_container.addChild(this.dot_preview);
    }

    if (this.obj_type == "object" && !this.el_object_form.getValue("path_mode") && this.curr_object) {
      this.dot_preview.clear();
      this.dot_preview.beginFill(
        parseInt(this.curr_object.color.replace("#", "0x"), 16),
        0.75
      );
      this.dot_preview.drawRect(
        this.pixi.half_place_mouse[0] - 2,
        this.pixi.half_place_mouse[1] - 2,
        4,
        4
      );
      this.dot_preview.endFill();
    } else {
      this.dot_preview.clear();
    }
  }

  loadObjectsFromSettings() {
    if (app.projSetting("scene") && app.projSetting("scene").objects) {
      let last_obj_name = "";
      if (this.curr_object) last_obj_name = this.curr_object.name;

      this.objects = [];
      let obj_ids = app.projSetting("scene").object_order;
      if (!obj_ids || obj_ids.length == 0)
        obj_ids = Object.keys(app.projSetting("scene").objects);

      for (let uuid of obj_ids) {
        let obj = app.projSetting("scene").objects[uuid];
        if (!obj) continue;

        this.addObject(obj);
        this.iterObject(obj.name, i_obj => {
          this.drawPoly(obj, i_obj.points, i_obj.poly);
          this.drawObjImage(obj, {
            sprite: i_obj.image,
            points: i_obj.points,
            poly: i_obj.poly
          })
        });
        this.refreshObjImages(obj.name);
      }
      this.setObject(last_obj_name);
    }
  }

  // check if Code.sprites has an image size for this object
  checkObjectSize(uuid) {
    let obj = this.objects[uuid];
    if (!obj.size_changed && Code.sprites.hasOwnProperty(obj.name)) {
      let spr_ref = Code.sprites[obj.name];
      obj.size[0] = spr_ref.frame_size[0];
      obj.size[1] = spr_ref.frame_size[1];
    }
    if (uuid === this.curr_object.uuid) {
      this.el_object_form.setValue("size", obj.size[0], 0);
      this.el_object_form.setValue("size", obj.size[1], 1);
    }
    this.export();
    return true;
  }

  setObject(name) {
    for (let uuid in this.objects) {
      if (this.objects[uuid].name === name) {
        this.curr_object = this.objects[uuid];
        this.el_object_form.setValue("name", this.curr_object.name);
        this.el_object_form.setValue("color", this.curr_object.color);
        this.checkObjectSize(uuid);
        this.el_object_form.container.style.display = "block";

        this.iterObjectInLayer(this.curr_layer.uuid, name, obj => {
          this.pixi.bringToFront(obj.image);
          this.pixi.bringToFront(obj.poly);
          this.pixi.bringToFront(obj.poly.text)
        });
        this.refreshObjectPaths();
      }
    }

    if (this.curr_object) {
      this.el_obj_list.selectItem(this.curr_object.name);
    } else {
      // no object of that name found
      this.el_object_form.container.style.display = "none";
    }
  }

  setObjectSize(uuid, size) {
    let [sizex, sizey] = size;
    let obj = this.objects[uuid];
    if (obj) {
      if (isNaN(sizex) || isNaN(sizey)) return obj.size.slice(); // reject new size, return old size

      if (sizex < 0) sizex = 0;
      if (sizey < 0) sizey = 0;
      obj.size[0] = sizex;
      obj.size[1] = sizey;
      obj.size_changed = true;

      this.iterObject(obj.name, _obj => {
        this.drawPoly(obj, _obj.points, _obj.poly);
      });

      this.export();

      this.objChangeEvent(uuid, "size", { size: size });
    }
  }

  deleteObject(uuid) {
    let obj = this.objects[uuid];
    // remove the object
    this.setObject(this.el_obj_list.removeItem(obj.name, true));

    // remove instances
    this.iterObject(obj.name, obj => {
      obj.poly.destroy();
    });

    delete app.projSetting("scene").objects[uuid];
    app
      .projSetting("scene")
      .object_order.splice(
        app.projSetting("scene").object_order.indexOf(uuid),
        1
      );
    delete this.objects[uuid];
    this.objChangeEvent(uuid, "delete");
    this.export();
  }

  renameObject(uuid, new_name, old_name) {
    let obj = this.objects[uuid];
    old_name = old_name || obj.name;
    delete this.obj_info[obj.name];
    this.el_obj_list.renameItem(old_name, new_name);
    obj.name = new_name;
    this.refreshObjImages(obj.name);

    if (!this.checkObjectSize(obj.uuid)) this.export();

    this.objChangeEvent(uuid, "name", {
      old_name: old_name,
      new_name: new_name,
    });
  }

  recolorObject(uuid, new_color) {
    let obj = this.objects[uuid];
    obj.color = new_color;
    this.iterObject(obj.name, _obj => {
      this.drawPoly(obj, _obj.points, _obj.poly);
    });
    this.el_obj_list.setItemColor(obj.name, new_color);
    this.export();

    this.objChangeEvent(uuid, "color", { color: new_color });
  }

  objChangeEvent(uuid, action, info) {
    if (!this.skip_change_event)
      dispatchEvent("sceneeditor.objectchanged", {
        src_file: this.file,
        uuid: uuid,
        action: action,
        info: info,
      });
  }

  getImage(path) {
    path = app.cleanPath(path);
    for (let img of this.images) {
      if (img.path == path) return img;
    }
  }

  loadImageTexture(img, onReady) {
    let image_obj = new Image();
    image_obj.onload = function () {
      let base = new PIXI.BaseTexture(image_obj);
      let texture = new PIXI.Texture(base);

      // save texture info
      img.texture = texture;

      if (onReady) onReady(img);
    };
    image_obj.src = "file://" + img.path;
  }

  setImage(path, onReady) {
    let this_ref = this;

    path = app.cleanPath(path);
    let img = this.getImage(path);
    if (img) {
      this_ref.loadImageTexture(img, function () {
        // set image inputs
        if (img.snap[0] > img.texture.width) img.snap[0] = img.texture.width;
        if (img.snap[1] > img.texture.height) img.snap[1] = img.texture.height;
        for (var property of ["snap", "offset", "spacing"]) {
          this_ref.el_image_form.setValue(property, img[property][0], 0);
          this_ref.el_image_form.setValue(property, img[property][1], 1);
        }
        this_ref.el_image_form.setValue("align", img.align || "top-left");

        if (onReady) onReady(img);
      });
    }
    // add image to scene library
    else {
      this.images.push({
        path: path,
        snap: this.curr_layer.snap.slice(0),
        offset: [0, 0],
        spacing: [0, 0],
        align: "top-left",
        uuid: guid(),
        pixi_images: {},
        pixi_tilemap: {},
      });
      this.export();
      this.setImage(path, onReady);
    }
  }

  addLayer(info) {
    var layer_name = "layer" + this.layers.length;

    info = info || {};
    ifndef_obj(info, {
      name: layer_name,
      depth: 0,
      offset: [0, 0],
      snap: [32, 32],
      uuid: guid(),
    });

    info.snap = info.snap.map(Number);

    info.container = new PIXI.Container();
    this.map_container.addChild(info.container);
    this.layers.push(info);
    this.el_layer_list.addItem(info.name);
    this.setLayer(info.name);

    return info.name;
  }

  removeLayer(name) {
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
        this.layers.splice(l, 1);
      }
    }
    this.el_layer_list.removeItem(name, true);
    if (this.layers.length > 0) {
      this.curr_layer = this.layers[Math.max(layer_index - 1, 0)];
    }
    this.refreshLayerList();
    this.export();
  }

  getLayer(name, is_uuid) {
    for (var l = 0; l < this.layers.length; l++) {
      if (
        (is_uuid && this.layers[l].uuid == name) ||
        this.layers[l].name === name
      )
        return this.layers[l];
    }
  }

  setLayer(name, is_uuid) {
    for (var l = 0; l < this.layers.length; l++) {
      if (
        (is_uuid && this.layers[l].uuid == name) ||
        this.layers[l].name == name
      ) {
        this.curr_layer = this.layers[l];
        this.el_layer_form.setValue("name", this.curr_layer.name);
        this.el_layer_form.setValue("snap", this.curr_layer.snap[0], 0);
        this.el_layer_form.setValue("snap", this.curr_layer.snap[1], 1);

        this.el_layer_list.selectItem(name);

        // only objects on this layer can be interacted with
        this.iterObjectInLayer(this.layers[l].uuid, true, obj => {
          obj.poly.interactive = true;
          //obj.poly.hitArea = null;
        });
      } else {
        // only objects on this layer can be interacted with
        this.iterObjectInLayer(this.layers[l].uuid, true, obj => {
          obj.poly.interactive = false;
          //obj.poly.hitArea = new PIXI.Rectangle(0,0,0,0);
        });
      }
    }
    this.refreshLayers();
    this.drawGrid();
    this.pixi.snap = this.curr_layer.snap.slice();
  }

  // refresh z-indexing of pixi layers
  refreshLayers() {
    let this_ref = this;
    this.el_layer_list
      .getItems()
      .reverse()
      .forEach((o, i) => {
        let layer = this_ref.getLayer(o);
        layer.container.alpha = 0.25;
        this_ref.map_container.setChildIndex(layer.container, i);
      });
    if (this.curr_layer) {
      //this.map_container.setChildIndex(this.curr_layer.container, this.map_container.children.length-1);
      this.curr_layer.container.alpha = 1;
    }
    this.refreshObjectPaths();
  }

  checkLoaded() {
    if (this.image_loads_left <= 0) {
      this.loaded = true;
    }
  }

  load(file_path) {
    this.file = file_path;
    this.loaded = false;

    var data = nwFS.readFileSync(file_path, "utf-8");
    this.skip_change_event = true;

    if (data.length > 5) {
      data = JSON.parse(data);

      // layers
      for (var l = 0; l < data.layers.length; l++) {
        this.addLayer(data.layers[l]);
      }
      this.refreshLayerList();

      // images
      this.image_loads_left = data.images.length;
      data.images.forEach((img, i) => {
        var full_path = nwPATH.normalize(
          nwPATH.join(app.project_path, img.path)
        );
        this.images.push({
          path: app.cleanPath(full_path),
          snap: img.snap,
          offset: img.offset,
          spacing: img.spacing,
          align: img.align,
          uuid: img.uuid,
          pixi_images: {},
          pixi_tilemap: {},
        });
        this.setImage(full_path, img_ref => {
          for (var layer_uuid in img.coords) {
            let layer = this.getLayer(layer_uuid, true);
            for (var coord of img.coords[layer_uuid]) {
              this.placeImageFrame(
                coord[0],
                coord[1],
                {
                  x: coord[2],
                  y: coord[3],
                  width: coord[4],
                  height: coord[5],
                },
                img_ref,
                layer,
                true
              );
            }
          }
          this.image_loads_left--;
          this.checkLoaded();
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

      // paths
      for (var obj_uuid in data.paths) {
        for (var layer_uuid in data.paths[obj_uuid]) {
          const layer_info = data.paths[obj_uuid][layer_uuid]

          for (var path_key1 in layer_info.graph) {
            for (var path_key2 in layer_info.graph[path_key1]) {
              const [x1, y1] = layer_info.node[path_key1]
              const [x2, y2] = layer_info.node[path_key2]
              const tag = layer_info.graph[path_key1][path_key2]
              this.addObjectPath(x1, y1, x2, y2, obj_uuid, layer_uuid, { tag })
            }
          }

        }
      }
      this.refreshObjectPaths()
      this.clearObjectPaths()

      // settings
      if (data.settings) {
        this.setLayer(data.settings.last_active_layer, true);
        this.refreshObjectType(data.settings.last_object_type);
        this.setObject(data.settings.last_object_name);
        this.setCameraPosition(
          data.settings.camera[0],
          data.settings.camera[1]
        );
      }
    }
    this.setTitle(nwPATH.basename(file_path));
    this.setOnClick(() => {
      SceneEditor.openScene(this.file);
    });
    this.setupMenu({
      close: true,
      rename: () => {
        this.setTitle(nwPATH.basename(this.file));
        SceneEditor.refreshSceneList();
      },
      delete: () => {
        this.deleted = true;
        SceneEditor.refreshSceneList();
        this.close(true);
      },
    });
    this.refreshLayerList()
    this.loadObjectsFromSettings()
    this.pixi.resize()

    if (!data.images || data.images.length == 0) this.loaded = true;

    this.skip_change_event = false;
  }

  export() {
    if (this.deleted || !this.loaded) return;

    let export_data = {
      objects: {},
      layers: [],
      images: [],
      settings: {
        camera: this.pixi.getCameraPosition().map(n => n / this.pixi.zoom),
        last_active_layer: this.curr_layer.uuid,
        last_object_type: this.obj_type,
        last_object_name: ifndef(this.curr_object, { name: null }).name,
      },
    };
    if (!app.projSetting("scene")) app.projSetting("scene", {});

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
        uuid: layer.uuid,
      });
      layer_names[layer.name] = true;
      layer_uuids[layer.uuid] = true;
    }

    // objects
    var obj_path_tag = {} // { layer_uuid: { obj_uuid: {  } }
    if (!app.projSetting("scene").objects)
      app.projSetting("scene").objects = {};

    app.projSetting("scene").object_order = Object.keys(this.objects);
    for (let obj_uuid in this.objects) {
      let obj = this.objects[obj_uuid];

      // save object info
      app.projSetting("scene").objects[obj_uuid] = obj;

      let polygons = {};

      // save object coordinates
      for (let layer_uuid in this.obj_polys[obj_uuid]) {
        if (layer_uuids[layer_uuid] == true) {
          let polys = this.obj_polys[obj_uuid][layer_uuid];
          if (polys.length > 0) {
            polygons[layer_uuid] = [];

            for (let p in polys) {
              const obj = polys[p]

              polygons[layer_uuid].push(
                [ifndef(obj.poly.tag, "")].concat(obj.points.slice())
              );

              // save path data for future use in export()
              if (obj.poly.tag) {
                if (!obj_path_tag[layer_uuid]) obj_path_tag[layer_uuid] = {}
                if (!obj_path_tag[layer_uuid][obj_uuid]) obj_path_tag[layer_uuid][obj_uuid] = {}
                obj_path_tag[layer_uuid][obj_uuid][(obj.poly.center.join(','))] = obj.poly.tag
              }
            }


            export_data.objects[obj.uuid] = polygons;
          }
        }
      }
    }

    //paths
    const path_data = {}
    /*
    { 
      obj_uuid: { 
        layer_uuid: { 
          node:{ 'x,y':[x,y,tag] }, 
          graph:{ 
            'x1,y1':{ 'x2,y2':true } 
          } 
        } 
      }
    }
    */

    const getNodeTag = (id, obj_uuid, layer_uuid) => {
      if (obj_path_tag[layer_uuid] && obj_path_tag[layer_uuid][obj_uuid] && obj_path_tag[layer_uuid][obj_uuid][id])
        return obj_path_tag[layer_uuid][obj_uuid][id]
    }

    for (var path_key in this.obj_paths) {
      const g = this.obj_paths[path_key]
      // obj_uuid
      if (!path_data[g.object.uuid])
        path_data[g.object.uuid] = {}
      const obj_data = path_data[g.object.uuid]
      // layer_uuid
      if (!obj_data[g.layer_uuid])
        obj_data[g.layer_uuid] = { node: {}, graph: {} }
      const layer_data = obj_data[g.layer_uuid]
      // layer_data.node
      const [id1, id2] = path_key.split(':')
      layer_data.node[id1] = id1.split(',').map(p => parseInt(p))
      layer_data.node[id2] = id2.split(',').map(p => parseInt(p))

      const tag1 = getNodeTag(id1, g.object.uuid, g.layer_uuid)
      if (tag1)
        layer_data.node[id1].push(tag1)
      const tag2 = getNodeTag(id2, g.object.uuid, g.layer_uuid)
      if (tag2)
        layer_data.node[id2].push(tag2)

      // layer_data.graph
      if (!layer_data.graph[id1]) layer_data.graph[id1] = {}
      if (!layer_data.graph[id2]) layer_data.graph[id2] = {}
      layer_data.graph[id1][id2] = g.tag || true
      layer_data.graph[id2][id1] = g.tag || true
    }
    export_data.paths = path_data

    //images
    let re_img_path = /.*(assets\/.*)/g;
    for (let obj of this.images) {
      let orig_path = app.cleanPath(
        nwPATH.relative(app.project_path, obj.path)
      );
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
        coords: {},
      };

      for (let i in obj.pixi_images) {
        let img = obj.pixi_images[i];
        if (img && layer_uuids[img.layer_uuid]) {
          if (!exp_img.coords[img.layer_uuid]) {
            exp_img.coords[img.layer_uuid] = [];
          }

          exp_img.coords[img.layer_uuid].push([
            img.x,
            img.y,
            img.frame.x,
            img.frame.y,
            img.frame.width,
            img.frame.height,
            img.snapped,
          ]);
        }
      }

      // only save image if it was used
      if (Object.keys(obj.pixi_images).length > 0) {
        export_data.images.push(exp_img);
      }
    }

    if (
      !(
        app.error_occured &&
        app.error_occured.error.stack.includes("sceneeditor")
      )
    ) {
      app.saveSettings();
      nwFS.writeFileSync(this.file, JSON.stringify(export_data));
    } else {
      console.log(this.file + " not saved cause of error", app.error_occured);
      blanke.toast(
        nwPATH.basename(this.file) +
        " not saved because an error occurred earlier!</br>Please re-open the IDE :("
      );
    }
  }

  static refreshSceneList(path) {
    app.removeSearchGroup("Map");
    addScenes(ifndef(path, app.project_path));
  }

  static openScene(file_path) {
    if (!FibWindow.focus(nwPATH.basename(file_path))) new SceneEditor(file_path);
  }
}

document.addEventListener("fileChange", function (e) {
  if (e.detail.file.includes("maps")) {
    SceneEditor.refreshSceneList();
  }
});

function addScenes(folder_path) {
  app.getAssets("map", files => {
    files.forEach(f => {
      app.addSearchKey({
        key: f.replace(app.getAssetPath("map") + "/", ""),
        onSelect: function (f) {
          SceneEditor.openScene(f);
        },
        tags: ["map"],
        args: [f],
        category: "Map",
        group: "Map",
      });
    });
  });
}

document.addEventListener("closeProject", function (e) {
  app.removeSearchGroup("Scene");
});

let last_new;
document.addEventListener("openProject", function (e) {
  var proj_path = e.detail.path;
  SceneEditor.refreshSceneList(proj_path);
  if (!app.projSetting("scene")) app.projSetting("scene", {});

  app.addSearchKey({
    key: "Add a map",
    onSelect: function () {
      app.getNewAssetPath("map", (path, name) => {
        nwFS.writeFile(path, "");
        // edit the new script
        app.addPendingQuickAccess(name);
        new SceneEditor(path);
      });
    },
    tags: ["new"],
  });
});
