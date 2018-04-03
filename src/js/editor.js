class Editor {
	constructor (app) {
		var workspace = app.getElement('#workspace');
		this.app = app;
		this.closed = false;

		var this_ref = this;

		// asset list
		this.asset_list = document.createElement("div");
		this.asset_list.classList.add('asset-list');

		// real content area
		this.content_area = document.createElement("div");
		this.content_area.classList.add('editor-content');
	}

	setupDragbox() {
		// create drag box
		this.dragbox = new DragBox(this.constructor.name)
		this.dragbox.appendTo(workspace);
		this.dragbox.width = 400;
		this.dragbox.height = 300;
		this.dragbox.drag_container.appendChild(this.asset_list);
		this.dragbox.appendChild(this.content_area);
		// menu button click
		this.dragbox.btn_menu.onclick = function(e) {
			this_ref.onMenuClick(e);
		}
	}

	setupTab() {
		// create tab
		this.container = new Tab(this.constructor.name);
		this.container.appendChild(this.content_area);
	}

	// Tab ONLY
	setOnClick() {
		this.container.setOnClick.apply(this.container, arguments);
	}

	close() {
		this.container.close();
		this.closed = true;
	}

	static closeAll (type) {
		var windows = app.getElements(".drag-container");
		for (var i = 0; i < windows.length; i++) {
			if (!type || (type && windows[i].dataset.type == type))
				windows[i].remove();
		}
	}

	addCallback(cb_name, new_func) {
		this.container[cb_name] = new_func;
	}

	// Dragbox ONLY
	get width() {
		return this.container.width;
	}

	// Dragbox ONLY
	get height() {
		return this.container.height;
	}

	hideMenuButton () {
		this.container.btn_menu.style.display = 'none';
	}

	appendChild (el) {
		this.content_area.appendChild(el);
	}

	setTitle (val) {
		this.container.setTitle(val);
	}

	onMenuClick (e) {
		this.toggleMenu();
	}

	toggleMenu () {
		this.asset_list.classList.toggle("open");
	}

	setAssetList (list, context_menu, on_menu_click) {
		var this_ref = this;

		// clear list
		this.asset_list.innerHTML = "";

		// context menu
		var menu = new nwGUI.Menu();
		context_menu.forEach(function(m){
			var item = new nwGUI.MenuItem(m);
			item.click = function() { on_menu_click(this.label, this_ref.list_value); }
			menu.append(item);
		});

		// add asset buttons
		for (var l = 0; l < list.length; l++) {
			let el_asset = this.app.createElement("button", "asset");
			el_asset.innerHTML = list[l];
			el_asset.onclick = function() {
				this_ref.toggleMenu(); 
				if (this_ref.onAssetSelect) this_ref.onAssetSelect(this.innerHTML);
			}
			el_asset.addEventListener('contextmenu', function(ev) { 
				ev.preventDefault();
				menu.popup(ev.x, ev.y);
				this_ref.list_value = ev.target.innerHTML;
				return false;
			});

			this.asset_list.appendChild(el_asset);
		}
	}
}

document.addEventListener("openProject", function(e){
	Editor.closeAll();
});