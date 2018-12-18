class ShaderPreview extends Editor {
	constructor (...args) {
		super(...args);
		// TODO: add option to give default values for el_sheet_form
		let this_ref = this;

		this.setupDragbox();
		this.removeHistory();
		this.hideMenuButton();
		this.container.width = 416;
		this.container.height = 288;

		this.setTitle('Shader Preview');

		// setup form
		this.el_edit_container = blanke.createElement("div","edit-container");
		this.el_shader_form = new BlankeForm([
			['name', 'text']
		]);
		this.appendChild(this.el_shader_form.container);

		this.el_pixel_editbox = blanke.createElement("textarea", "code");
		this.el_pixel_editbox.classList.add("code");
		this.el_vertex_editbox = blanke.createElement("textarea", "code");
		this.el_vertex_editbox.classList.add("code");

		this.appendChild(this.el_pixel_editbox);
		this.appendChild(this.el_vertex_editbox);

		this.el_pixel_code = CodeMirror.fromTextArea(this.el_pixel_editbox, {
			mode: "C",
			theme: "material",
            smartIndent : true,
            lineNumbers : true,
            lineWrapping : false,
            indentUnit : 4,
            tabSize : 4,
            indentWithTabs : true,
            highlightSelectionMatches: {showToken: /\w{3,}/, annotateScrollbar: true},
            matchBrackets: true,
            completeSingle: false,
            extraKeys: {
            	"Shift-Tab": "indentLess",
            	"Ctrl-F": "findPersistent"/*,
            	"Ctrl-Space": "autocomplete"*/
            }
		});
		this.el_vertex_code = CodeMirror.fromTextArea(this.el_vertex_editbox, {
			mode: "C",
			theme: "material",
            smartIndent : true,
            lineNumbers : true,
            lineWrapping : false,
            indentUnit : 4,
            tabSize : 4,
            indentWithTabs : true,
            highlightSelectionMatches: {showToken: /\w{3,}/, annotateScrollbar: true},
            matchBrackets: true,
            completeSingle: false,
            extraKeys: {
            	"Shift-Tab": "indentLess",
            	"Ctrl-F": "findPersistent"/*,
            	"Ctrl-Space": "autocomplete"*/
            }
		});

		// add animation preview elements
		this.el_prvw_container = blanke.createElement("div", "prvw-container");

		this.appendChild(this.el_btn_show_prvw);
		this.appendChild(this.el_prvw_container);
	}

	_onCopyCode () {
		if (this.onCopyCode) {
			blanke.toast("Shader code copied!");
			this.onCopyCode(this.getValues());
		} else {
			blanke.toast("Can't copy any code right now.");
		}
	}

	getValues () {
		let name = this.el_sheet_form.getValue("name");
		let offset = [this.el_sheet_form.getValue("variables",0), this.el_sheet_form.getValue("offset",1)];
		let speed = this.el_sheet_form.getValue("speed");
		let frame_dims = [this.el_sheet_form.getValue("frame size",0), this.el_sheet_form.getValue("frame size",1)];

		return {'name':name,'variables':offset,'effect':speed,'vertex':frame_dims}
	}
}

document.addEventListener("openProject", function(e){
	app.addSearchKey({
		key: 'Preview a shader',
		onSelect: function() {
			new ShaderPreview(app);
		},
		tags: ['view']
	});
	/*
	app.addSearchKey({
		key: 'Add images',
		onSelect: function() {
			blanke.chooseFile('file', function(files){
				files = files.split(';');
				for (var f of files) {
					app.addAsset('image',f);
				}
			}, true, true);
		},
		tags: ['view']
	});*/
});