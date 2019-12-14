const IMAGE_SETTINGS = {
    frame_size: [32,32]
}

class ImageEditor extends Editor {
    constructor () {
        super();
        this.setupFibWindow();
        // create elements
        this.el_top_right_container = app.createElement('div','top-right-container');
        this.el_file_select = app.createElement('select','file-select');
        this.el_image_props = new BlankeForm([
            ['frame_size', 'number', {'inputs':2, 'separator':'x'}],
        ])
        this.el_sidebar = app.createElement('div','sidebar');
        this.el_tools = app.createElement('div','tools');
        this.el_layers = new BlankeListView({object_type:"layer"});
        this.pixi = new BlankePixi();
		this.addCallback('onResize', () => {
			this.pixi.resize();
		});
		this.appendBackground(this.pixi.view);
        // setup pixi
		this.pixi.stage.interactive = true;
		this.pixi.stage.hitArea = this.pixi.screen;
        this.pixi.view.addEventListener('contextmenu', (e) => {
			e.preventDefault();
		});
        // add elements to Editor
        this.appendChild(this.el_top_right_container);
        this.appendChild(this.el_sidebar);
        this.appendChild(this.pixi.view);
    }
    openFile (img_path) {
        this.setTitle(nwPATH.basename(img_path));
    }
}

document.addEventListener("openProject", e => {
    app.addSearchKey({
        key: "Open image editor",
        onSelect: () => {
            const imgEdit = new ImageEditor();
        }
    })
});