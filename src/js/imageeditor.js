const EDITOR_TITLE = "Image Editor";
const DEFAULT_IMAGE_SETTINGS = {
    frame_size: [256,256],
    frames: 1,
    position: [0,0],
    spacing: [0,0]
}
const MARGIN_LEFT = 5;
const MARGIN_TOP = 40;
let colors = [
    'f44336','E91E63','9C27B0','673AB7','3F51B5','2196F3','03A9F4','00BCD4','009688',
    '4CAF50','8BC34A','CDDC39','FFEB3B','FFC107','FF9800','FF5722','795548','9E9E9E',
    '607D8B','FFFFFF','000000'];
let img_editors = [];

class ImageEditor extends Editor {
    constructor (file) {
        super();
        this.setupFibWindow();
        this.file = null;
        this.img_settings = {};
        this.curr_tool = 'pencil';
        this.curr_color = 0x000000;
        this.cursor = [0,0];
        // create elements
        this.el_top_right_container = app.createElement('div','top-right-container');
        let form_options = [
            ['image','select',{'label':false}],
            ['image settings', true],
            ['position', 'number', {'inputs':2, 'separator':'x'}],
            ['spacing', 'number'],
            ['frame_size', 'number', {'inputs':2, 'separator':'x', 'min':1}],
            ['frames', 'number', {'min':1}],
            ['tools'],
            ['pencil', 'icon-button'],
            ['line', 'icon-button']
        ]
        this.el_image_form = new BlankeForm(form_options);
        this.el_sidebar = app.createElement('div','sidebar');
        this.el_colors = app.createElement('div','color-container');
        //this.el_layers = new BlankeListView({object_type:"layer"});
        this.pixi = new BlankePixi();
        this.img_container = new PIXI.Container();
        this.crosshair = new PIXI.Graphics();
        this.edit_container = new PIXI.Container(); // all the stuff that will be saved to image file
        this.img_background = new PIXI.Graphics();
        this.img_edits = new PIXI.Graphics();
        this.edit_container.addChild(this.img_edits);
        this.img_container.addChild(this.img_background);
        this.img_container.addChild(this.edit_container);
        this.img_container.addChild(this.crosshair);
        this.pixi.stage.addChild(this.img_container);

        // setup el_image_form   
        form_options.forEach(s => {
            if (s.length > 1) {
                this.el_image_form.onChange(s[0], val => {
                    this.img_settings[s[0]] = val;
                    this.redrawBackground();
                    // tools
                    if (['pencil','line'].includes(s[0])) {
                        this.curr_tool = s[0];
                        console.log(this.curr_tool)
                    }
                });
            }
        })

        // setup el_file_select
        document.addEventListener('fileChange', e => {
            if (app.findAssetType(e.detail.file) == "image")
                this.refreshImageList();
        });
        this.refreshImageList();
        this.el_image_form.onChange('image', value => {
            this.openFile(value);
        })

        // setup pixi
        //this.img_container.sortChildren();
		this.pixi.stage.interactive = true;
        this.pixi.view.addEventListener('contextmenu', (e) => {
			e.preventDefault();
        });
		this.addCallback('onResize', () => {
			this.pixi.resize();
        });
        this.pixi.on('cameraChange', e => {
            this.img_container.position.set(e.x, e.y);
        });
        this.pixi.on('mouseMove', (e, info) => {
            let { mx, my, btn } = info;
            this.cursor = [ Math.floor(mx), Math.floor(my) ];
            let cross = this.crosshair;
            cross.clear();
            cross.lineStyle(Math.max(1/this.pixi.zoom,1), this.curr_color, 0.3);
            let w = this.pixi.width/Math.min(this.pixi.zoom, 1);
            let h = this.pixi.height/Math.min(this.pixi.zoom, 1);
            let camx = this.pixi.camera[0];
            let camy = this.pixi.camera[1];
            // vertical
            cross.moveTo(this.cursor[0] + 0.5,  -h - camy);
            cross.lineTo(this.cursor[0] + 0.5,  h - camy);
            // horizontal
            cross.moveTo(-w - camx,    this.cursor[1] + 0.5);
            cross.lineTo(w - camx,     this.cursor[1] + 0.5);
            // center
            cross.lineStyle(0, this.curr_color, 0.3);
            cross.beginFill(this.curr_color);
            cross.drawRect(this.cursor[0], this.cursor[1], 1, 1);
            cross.endFill();
            
            if (this.curr_tool == "pencil" && btn == 0) {
                this.drawPoint(this.cursor[0], this.cursor[1], this.curr_color);
            }
        });
        this.pixi.on('movePlace', (e, info) => {
            console.log(this.curr_tool)
            if (this.curr_tool == "pencil")
                this.drawPoint(this.cursors[0], this.cursor[1], this.curr_color);
            if (this.curr_tool == "line")
                this.getPoint(this.cursor[0], this.cursor[1]);
        });
        this.pixi.setCameraPosition(MARGIN_LEFT,MARGIN_TOP);  
        this.save_key_up = true; 
        this.pixi.on('keyDown', (e, info) => {
            if (e.ctrlKey && e.key == "s" && this.save_key_up) {
                this.save();
                this.save_key_up = false;
            }
        });
        this.pixi.on('keyUp', (e, info) => {
          if (e.key == 's') this.save_key_up = true;  
        })
        
        // setup el_colors
        const addColor = (c) => {
            let el_color = app.createElement('div','color');
            el_color.style.backgroundColor = `#${c}`;
            el_color.title = `#${c}`;
            el_color.value = parseInt(`0x${c}`);
            el_color.addEventListener('click', e => {
                this.curr_color = e.target.value;
            });
            el_color.addEventListener('contextmenu', e => {
                app.contextMenu(e.x, e.y, [
                    {
                        label:'edit', 
                        click: () => {
                            blanke.askColor(`#${c}`, (e) => {
                                el_color.style.backgroundColor = e.target.value;
                                el_color.title = e.target.value;
                                el_color.value = e.target.value;
                            });
                        }
                    },
                    {
                        label:'delete',
                        click: () => {
                            blanke.destroyElement(el_color);
                        }
                    }
                ])
            });
            this.el_colors.appendChild(el_color);
        }
        colors.forEach(c => addColor(c));
        let el_add_color = app.createElement('div','add-color');
        el_add_color.innerHTML = "+";
        el_add_color.addEventListener('click', e => {
            addColor('FFFFFF')
        });
        this.el_colors.insertBefore(el_add_color, this.el_colors.firstChild);

        // add elements to Editor
        this.el_top_right_container.appendChild(this.el_image_form.container);
        this.el_sidebar.appendChild(this.el_colors);
        //this.el_sidebar.appendChild(this.el_layers);
        this.appendChild(this.el_top_right_container);
        this.appendChild(this.el_sidebar);
        this.appendChild(this.pixi.view);
        this.appendBackground(this.pixi.view);

        this.setTitle(EDITOR_TITLE);
		this.setOnClick(() => {
            openImage(this.file || EDITOR_TITLE)
        });
        
        if (file && file != EDITOR_TITLE)
            this.openFile(file)
        img_editors.push(this);
    }
    onClose () {
        img_editors = img_editors.filter(e => e.container.guid != this.container.guid);
        img_editors.forEach(e => {
            e.refreshImageList();
        })
    }
    openFile (path) {
        this.file = path;
        let fname = app.shortenAsset(path);
        this.setTitle(nwPATH.basename(path));
        // project settings
        if (!app.projSetting("imageeditor")) app.projSetting("imageeditor",{})
        let image_edit_settings = app.projSetting("imageeditor");
        
        this.img_edits.clear();

        const setupForm = () => {
            app.saveSettings();
            this.redrawBackground();
            let img_sprite = PIXI.Sprite.from(this.file);
            this.edit_container.addChild(img_sprite);
            this.pixi.orderComponents([
                img_sprite, this.img_edits
            ])
            this.pixi.orderComponents([
                this.img_background, this.edit_container, this.crosshair
            ])
            this.el_image_form.useValues(this.img_settings);
        }
    
        let new_file = false;
        if (!image_edit_settings[fname]) {
            image_edit_settings[fname] = {}
            new_file = true;
        }
        ifndef_obj(image_edit_settings[fname], DEFAULT_IMAGE_SETTINGS);
        this.img_settings = image_edit_settings[fname];
        this.img_settings.image = this.file;
        
        if (new_file) {
            let img = new Image();
            img.onload = () => {
                this.img_settings.frame_size = [img.width, img.height];
                setupForm();
            }
            img.src = "file://"+path;
        } else 
            setupForm();
    }
    refreshImageList () {
        let sel_str = `<option class="placeholder" value="" disabled ${this.file ? '' : 'selected'}>Select an image</option>`;
		this.el_image_form.getInput('image').innerHTML = sel_str;
		app.getAssets('image', files => {
			files.forEach(f => {
                if (!img_editors.some(e => e.file == f && e.file != this.file)) {
                    var img_path = nwPATH.basename(f);
                    sel_str += `<option value="${f}">${img_path}</option>`;
                }
			})
            this.el_image_form.getInput('image').innerHTML = sel_str;
            this.el_image_form.useValues(this.img_settings);
		});
    }
    redrawBackground () {
        let bg = this.img_background;
        let set = this.img_settings;
        ifndef_obj(this.img_settings, DEFAULT_IMAGE_SETTINGS);
        bg.clear();
        let white_tile = true;
        let t_size = 10;

        let width = set.position[0] + ((set.frame_size[0] + set.spacing) * set.frames) - (set.spacing);
        let height = set.position[1] + set.frame_size[1];
        // draw transparency tiles
        for (let x = set.position[0]; x < width; x += t_size) {
            white_tile = (x/t_size % 2 == 0) ? true : false;
            for (let y = set.position[1]; y < height; y += t_size) {
                bg.beginFill(white_tile ? 0xFFFFFF : 0xBFBFBF);
                bg.drawRect(x, y, x + t_size > width ? width - x : t_size, y + t_size > height ? height - y : t_size)
                bg.endFill();
                white_tile = !white_tile;
            }
        }
        // draw frame rects
        for (let x = set.position[0]; x < width; x += set.frame_size[0] + set.spacing) {
            bg.lineStyle(1, app.getThemeColor('ide-accent'), 0.5);
            bg.drawRect(x,-set.position[1],set.frame_size[0],set.frame_size[1]);
        }
    }
    drawPoint (x, y, color) {
        let edit = this.img_edits;
        edit.beginFill(color);
        edit.drawRect(x, y, 1, 1);
    }
    getPoint (x, y) {
        let pixels = this.pixi.renderer.extract.pixels(this.edit_container);
        let i = (y * this.edit_container.width + x) * 4;
        let rgba = { r:pixels[i], g:pixels[i+1], b:pixels[i+2], a:[pixels[i+3]] }
        console.log(rgba);
    }
    save () {
        if (this.file) {
            let img = this.pixi.renderer.plugins.extract.image(this.edit_container)
            img.onload = () => {
                let buf = Buffer.from(img.src.replace(/^data:image\/\w+;base64,/, ""), 'base64');
                nwFS.writeFile(this.file, buf);
            }
        }
    }
}

const openImage = f => {
    if (!FibWindow.focus(nwPATH.basename(f || EDITOR_TITLE)))
        new ImageEditor(f);
}

document.addEventListener("openProject", e => {
    app.addSearchKey({
        key: "Open image editor",
        onSelect: () => {
            openImage();
        }
    })
});

document.addEventListener("themeChanged", e => {
    img_editors.forEach(e => {
        e.redrawBackground();
    })
})