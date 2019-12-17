const EDITOR_TITLE = "Image Editor";
const DEFAULT_IMAGE_SETTINGS = {
    frame_size: [256,256],
    frames: 1,
    position: [0,0],
    spacing: 0
}
const MARGIN_LEFT = 5;
const MARGIN_TOP = 40;
const TOOLS = ['pencil','line','eraser'];
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
        this.curr_color = 0x000000;
        this.cursor = [0,0];
        this.img_left = 0;
        this.img_top = 0;
        this.img_width = 0;
        this.img_height = 0;
        this.erase_coords = [];
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
            ...TOOLS.map(t => [t, 'icon-button'])

        ]
        this.el_image_form = new BlankeForm(form_options);
        this.el_sidebar = app.createElement('div','sidebar');
        this.el_colors = app.createElement('div','color-container');
        //this.el_layers = new BlankeListView({object_type:"layer"});
        this.pixi = new BlankePixi();
        this.img_container = new PIXI.Container();
        this.crosshair = new PIXI.Graphics();
        // image editing-related
        this.edit_container = new PIXI.Container(); // all the stuff that will be saved to image file
        this.img_background = new PIXI.Graphics();
        this.img_edits = new PIXI.Graphics();
        this.img_rtx = PIXI.RenderTexture.create(this.img_width, this.img_height); 
        this.img_sprite = new PIXI.Sprite(this.img_rtx); // only this gets shown
        // masks
        this.img_mask = new PIXI.Graphics();
        this.img_erase = new PIXI.Graphics();
        this.edit_container.mask = this.img_mask;
        this.edit_container.addChild(this.img_sprite, this.img_edits);
        this.img_container.addChild(this.img_background, this.edit_container, this.crosshair);
        this.pixi.stage.addChild(this.img_container);

        // setup el_image_form   
        form_options.forEach(s => {
            if (s.length > 1) {
                this.el_image_form.onChange(s[0], val => {
                    this.img_settings[s[0]] = val;
                    this.redrawBackground();
                    this.setTool(s[0]);
                });
            }
        });
        this.setTool(TOOLS[0]);

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
            this.drawCrosshair();
            
            if (this.curr_tool == "pencil" && btn == 0) 
                this.drawPoint(this.cursor[0], this.cursor[1], this.curr_color);
            if (this.curr_tool == "eraser" && btn == 0)
                this.erase('drawRect',this.cursor[0], this.cursor[1], 1, 1);
        });
        this.pixi.on('mousePlace', (e, info) => {
            if (this.curr_tool == "pencil")
                this.drawPoint(this.cursor[0], this.cursor[1], this.curr_color);
            if (this.curr_tool == "line")
                this.getPoint(this.cursor[0], this.cursor[1]);
            if (this.curr_tool == "eraser")
                this.erase('drawRect',this.cursor[0], this.cursor[1], 1, 1);
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
        /*
        this.pixi.ticker.add(() => {
            this.pixi.renderer.render(container, this.img_rtx);
        });*/
        
        // setup el_colors
        const addColor = (c) => {
            let el_color = app.createElement('div','color');
            el_color.style.backgroundColor = `#${c}`;
            el_color.title = `#${c}`;
            el_color.value = parseInt(`0x${c}`);
            el_color.addEventListener('click', e => {
                this.curr_color = e.target.value;
                this.drawCrosshair();
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
            openImage(this.file)
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
        
        const setupForm = () => {
            app.saveSettings();
            this.redrawBackground();
            this.pixi.setCameraPosition((this.pixi.width - this.img_width) / 2, (this.pixi.height - this.img_height) / 2);
            this.el_image_form.useValues(this.img_settings);
             
            this.pixi.orderComponents([
                this.img_background, this.edit_container, this.crosshair
            ])
            if (nwFS.pathExistsSync(path)) {
                this.initial_spr = PIXI.Sprite.from(path)
                this.renderImageTexture(null,this.initial_spr);
            }
        }
    
        let new_file = false;
        if (!image_edit_settings[fname]) {
            image_edit_settings[fname] = {}
            new_file = true;
        }
        ifndef_obj(image_edit_settings[fname], DEFAULT_IMAGE_SETTINGS);
        this.img_settings = image_edit_settings[fname];
        this.img_settings.image = this.file;
        
        if (new_file && nwFS.pathExistsSync(path)) {
            let img = new Image();
            img.onload = () => {
                this.img_settings.frame_size = [img.width, img.height];
                setupForm();
            }
            img.src = "file://"+path;
        } else 
            setupForm();
    }
    drawCrosshair () {
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

        this.img_left = set.position[0];
        this.img_top = set.position[1];
        this.img_width = set.position[0] + ((set.frame_size[0] + set.spacing) * set.frames) - (set.spacing);
        this.img_height = set.position[1] + set.frame_size[1];

        this.pixi.setCameraBounds(0,0,this.pixi.width-this.img_width,this.pixi.height-this.img_height);
        // draw transparency tiles
        for (let x = this.img_left; x < this.img_width; x += t_size) {
            white_tile = (x/t_size % 2 == 0) ? true : false;
            for (let y = this.img_top; y < this.img_height; y += t_size) {
                bg.beginFill(white_tile ? 0xFFFFFF : 0xBFBFBF);
                bg.drawRect(x, y, x + t_size > this.img_width ? this.img_width - x : t_size, y + t_size > this.img_height ? this.img_height - y : t_size)
                bg.endFill();
                white_tile = !white_tile;
            }
        }
        // draw frame rects
        for (let x = this.img_left; x < this.img_width; x += set.frame_size[0] + set.spacing) {
            bg.lineStyle(1, app.getThemeColor('ide-accent'), 0.5);
            bg.drawRect(x,-this.img_top,set.frame_size[0],set.frame_size[1]);
        }
        // update mask
        let mask = this.img_mask;
        mask.clear();
        mask.beginFill(0xFFFFFF);
        mask.drawRect(this.img_left, this.img_top, this.img_width, this.img_height);
        mask.endFill();
        // resize rendertexture
        if (this.img_rtx)
            this.img_rtx.resize(this.img_width, this.img_height);
    }
    setTool (name) {
        if (TOOLS.includes(name)) {
            this.curr_tool = 'pencil';
            this.curr_tool = name;
            this.el_image_form.getInput(name).classList.add('selected');
            TOOLS.forEach(t => {
                if (t != name) this.el_image_form.getInput(t).classList.remove('selected')
            });
        }
    }
    drawPoint (x, y, color) {
        if (x >= 0 && y >= 0 && x < this.img_width && y < this.img_height) {
            let edit = this.img_edits;
            edit.clear();
            edit.beginFill(color);
            edit.drawRect(x, y, 1, 1);
            this.renderImageTexture();
        }
    }
    getPoint (x, y) {
        let pixels = this.pixi.renderer.extract.pixels(this.edit_container);
        let i = (y * this.edit_container.width + x) * 4;
        return { r:pixels[i], g:pixels[i+1], b:pixels[i+2], a:pixels[i+3] }
    }
    erase (_type, ...args) {
        let mask = this.img_erase;
        mask.clear();
        mask.beginFill(0xFFFFFF);
        mask.drawRect(0,0,this.img_width,this.img_height);
        mask.beginHole();
        if (_type) mask[_type](...args);
        mask.endHole();
        mask.endFill();
        this.renderImageTexture(true);
        mask.clear();
    }
    renderImageTexture (mask, spr) {
        //if (mask) this.fake_container.mask = this.img_erase;
        this.pixi.renderer.render(spr || this.edit_container, this.img_rtx);
    }
    save () {
        if (this.file) {
            let rtx = PIXI.RenderTexture.create(this.img_width, this.img_height);
            this.pixi.renderer.render(this.edit_container, rtx);
            let img = this.pixi.renderer.plugins.extract.image(rtx);
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
			app.getNewAssetPath('image', (path, name) => {
                openImage(path);
            });
        }
    })
});

document.addEventListener("themeChanged", e => {
    img_editors.forEach(e => {
        e.redrawBackground();
    })
})