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
        this.curr_tool = '';
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
            ['pencil', 'icon-button']
        ]
        this.el_image_form = new BlankeForm(form_options);
        this.el_sidebar = app.createElement('div','sidebar');
        this.el_colors = app.createElement('div','color-container');
        //this.el_layers = new BlankeListView({object_type:"layer"});
        this.pixi = new BlankePixi();
        this.img_container = new PIXI.Container();
        this.img_background = new PIXI.Graphics();
        this.crosshair = new PIXI.Graphics();
        this.img_background.zIndex = 0;
        this.crosshair.zIndex = 2;
        this.img_container.sortableChildren = true;
        this.img_container.addChild(this.img_background);
        this.img_container.addChild(this.crosshair);
        this.pixi.stage.addChild(this.img_container);
        this.img_container.updateTransform();

        // setup el_image_form   
        form_options.forEach(s => {
            if (s.length > 1) {
                this.el_image_form.onChange(s[0], val => {
                    this.img_settings[s[0]] = val;
                    this.redrawBackground();
                    // tools
                    if (['pencil'].includes(s[0])) {
                        this.curr_tool = s[0];
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
            let { mx, my } = info;
            let cross = this.crosshair;
            cross.clear();
            cross.lineStyle(Math.max(1/this.pixi.zoom,1), 0x000000, 0.3);
            let w = this.pixi.width/Math.min(this.pixi.zoom, 1);
            let h = this.pixi.height/Math.min(this.pixi.zoom, 1);
            let camx = this.pixi.camera[0];
            let camy = this.pixi.camera[1];
            // vertical
            cross.moveTo(Math.floor(mx) + 0.5,  -h - camy);
            cross.lineTo(Math.floor(mx) + 0.5,  h - camy);
            // horizontal
            cross.moveTo(-w - camx,    Math.floor(my) + 0.5);
            cross.lineTo(w - camx,     Math.floor(my) + 0.5);
        });
        this.pixi.setCameraPosition(MARGIN_LEFT,MARGIN_TOP);   
        
        // setup el_colors
        for (let c of colors) {
            let el_color = app.createElement('div','color');
            el_color.style.backgroundColor = '0x'+c;
        }

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
            openImage(nwPATH.basename(this.file || EDITOR_TITLE))
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
            let img_sprite = PIXI.Sprite.from(this.file);
            img_sprite.zIndex = 1;
            this.img_container.addChild(img_sprite);
            this.img_container.updateTransform();
            //this.img_container.sortChildren();
        }
    
        let new_file = false;
        if (!image_edit_settings[fname]) {
            image_edit_settings[fname] = {}
            new_file = true;
        }
        ifndef_obj(image_edit_settings[fname], DEFAULT_IMAGE_SETTINGS);
        this.img_settings = image_edit_settings[fname];
        this.el_image_form.useValues(this.img_settings)
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
                if (!img_editors.some(e => e.file == f)) {
                    var img_path = nwPATH.basename(f);
                    sel_str += `<option value="${f}" ${this.file == img_path ? 'selected' : ''}>${img_path}</option>`;
                }
			})
			this.el_image_form.getInput('image').innerHTML = sel_str;
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
            bg.drawRect(x,0,set.frame_size[0],set.frame_size[1]);
        }
    }
}

const openImage = f => {
    if (!FibWindow.focus(f || EDITOR_TITLE))
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