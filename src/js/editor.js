class Editor {
	constructor (app) {
		var workspace = app.getElement('#workspace');
		this.app = app;
		this.closed = false;

		// create drag box
		this.dragbox = new DragBox(this.constructor.name)

		this.dragbox.appendTo(workspace);
		this.dragbox.width = 300;
		this.dragbox.height = 250;

		// asset list
		this.asset_list = document.createElement("div");
		this.asset_list.classList.add('asset-list');

		// real content area
		this.content_area = document.createElement("div");
		this.content_area.classList.add('editor-content');

		this.dragbox.drag_container.appendChild(this.asset_list);
		this.dragbox.appendChild(this.content_area);

		// menu button click
		var this_ref = this;
		this.dragbox.btn_menu.onclick = function(e) {
			this_ref.onMenuClick(e);
		}

		// watch for file changes
		var this_ref;
	}

	close() {
		this.dragbox.close();
		this.closed = true;
	}

	static closeAll () {
		var windows = app.getElements(".drag-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].remove();
		}
	}

	addCallback(cb_name, new_func) {
		this.dragbox[cb_name] = new_func;
	}

	get width() {
		return this.dragbox.drag_content.offsetWidth;
	}

	get height() {
		return this.dragbox.drag_content.offsetHeight;
	}

	hideMenuButton () {
		this.dragbox.btn_menu.style.display = 'none';
	}

	appendChild (el) {
		this.content_area.appendChild(el);
	}

	setTitle (val) {
		this.dragbox.setTitle(val);
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
			var el_asset = this.app.createElement("button", "asset");
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