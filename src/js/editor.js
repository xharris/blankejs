class Editor {
	constructor (app) {
		var workspace = app.getElement('#workspace');
		this.app = app;

		// create drag box
		this.dragbox = new DragBox('Code');
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
		this.dragbox.btn_menu.onclick = function() {
			this_ref.toggleMenu();
		}

		// watch for file changes
		var this_ref;
		document.addEventListener('fileChange', function(e){
			if (this_ref.onFileChange) this_ref.onFileChange(e.detail.type, e.detail.file);
		});
	}

	appendChild (el) {
		this.content_area.appendChild(el);
	}

	setTitle (val) {
		this.dragbox.setTitle(val);
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