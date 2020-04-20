const { Menu, MenuItem } = require("electron");

var editors = [];

const removeID = id => {
  editors = editors.filter(edit => edit && edit.id !== id)
}

class Editor {
  constructor() {
    this.app = app;
    this.closed = false;
    this.id = guid();

    // asset list
    this.asset_list = document.createElement("div");
    this.asset_list.classList.add("asset-list");

    // real content area
    this.content_area = document.createElement("div");
    this.content_area.classList.add("editor-content");

    editors.push(this);
  }

  setupPopup(content) {
    this.container_type = "dragbox";
    // create drag box
    this.container = new DragBox(content || this.constructor.name);
  }

  setupDragbox(content) {
    this.container_type = "dragbox";
    // create drag box
    this.container = new DragBox(content || this.constructor.name);
    this.container.appendTo(workspace);
    this.container.width = 400;
    this.container.height = 300;
    this.container.drag_container.appendChild(this.asset_list);
    this.container.appendChild(this.content_area);
    // menu button click
    this.container.btn_menu.onclick = e => {
      removeID(this.id);
      this.onMenuClick(e);
    };
    this.container.onClose = (...args) => this.onClose(...args);
    this.container.onBeforeClose = (...args) => this.onBeforeClose(...args);
    app.refreshQuickAccess();
    return this;
  }

  setupTab(content) {
    var this_ref = this;
    this.container_type = "tab";
    // create tab
    this.container = new Tab(content || this.constructor.name);
    this.container.appendChild(this.content_area);
    app.setHistoryActive(this.container.history_id, true);
    app.setHistoryContextMenu(this.container.history_id, function (e) {
      this_ref.onMenuClick(e);
    });
    this.container.onClose = (...args) => {
      removeID(this.id);
      this.onClose(...args);
      app.refreshQuickAccess();
    };
    this.container.onBeforeClose = (...args) => this.onBeforeClose(...args);
    app.refreshQuickAccess();
    return this;
  }

  setupFibWindow(content) {
    var this_ref = this;
    this.container_type = "fibwindow";
    this.container = new FibWindow(
      typeof content == "string" ? content : this.constructor.name
    );
    this.container.appendTo(workspace);
    this.container.appendChild(this.content_area);
    this.container.btn_menu.onclick = function (e) {
      this_ref.onMenuClick(e);
    };
    app.setHistoryActive(this.container.history_id, true);
    app.setHistoryContextMenu(this.container.history_id, function (e) {
      this_ref.onMenuClick(e);
    });
    this.container.onClose = (...args) => {
      removeID(this.id);
      this.onClose(...args);
      app.refreshQuickAccess();
    };
    this.container.onBeforeClose = (...args) => this.onBeforeClose(...args);
    app.refreshQuickAccess();
    return this;
  }

  setupSideWindow(transparent, content) {
    let this_ref = this;
    this.container_type = "sidewindow";
    this.container = new SideWindow(content || this.constructor.name);
    this.container.appendChild(this.content_area);
    this.container.btn_menu.onclick = function (e) {
      this_ref.onMenuClick(e);
    };
    app.setHistoryActive(this.container.history_id, true);
    app.setHistoryContextMenu(this.container.history_id, function (e) {
      this_ref.onMenuClick(e);
    });
    this.container.onClose = (...args) => {
      removeID(this.id);
      this.onClose(...args);
      app.refreshQuickAccess();
    };
    if (transparent) this.container.el_container.classList.add("transparent");
    app.refreshQuickAccess();
    return this;
  }

  setupMenu(opt) {
    let items = [];
    if (!opt.file_key) opt.file_key = "file";

    document.addEventListener('file_move', (e) => {
      if (e.detail.old_path === app.cleanPath(this[opt.file_key])) {
        this[opt.file_key] = e.detail.new_path;
      }
    })

    if (opt.close) {
      items.push({
        label: "close",
        click: () => {
          this.close();
        },
      });
    }

    // file_key='file' : where filename is stored
    // rename : callback when file is renamed
    if (opt.rename) {
      items.push({
        label: "rename",
        click: () => {
          app.renameModal(this[opt.file_key], {
            success: (new_path) => {
              this[opt.file_key] = new_path;
              if (typeof opt.rename == "function")
                opt.rename(new_path, full_path);
            }
          })
        },
      });
    }

    // file_key='file'
    // delete
    if (opt.delete) {
      items.push({
        label: "delete",
        click: () => {
          app.deleteModal(this[opt.file_key], {
            success: () => {
              this.deleted = true;
              if (typeof opt.delete == "function") opt.delete();
            }
          })
        },
      });
    }

    this.onMenuClick = e => {
      let items_copy = [...items];
      if (opt.extra) items_copy = items_copy.concat(opt.extra());
      app.contextMenu(e.x, e.y, items_copy);
    };
  }

  removeHistory() {
    if (this.container) app.removeHistory(this.container.history_id);
  }

  setOnClick() {
    let fn = arguments;
    if (this.container_type != "tab") fn = arguments[0];
    let old_fn = fn;

    if (["tab", "fibwindow", "sidewindow"].includes(this.container_type))
      fn = (...args) => {
        app.refreshQuickAccess(this.getTitle());
        if (this.container.onTabFocus) this.container.onTabFocus();
        old_fn(...args);
      };

    if (this.container_type == "tab")
      this.container.setOnClick.apply(this.container, fn);
    if (this.container_type == "fibwindow")
      app.setHistoryClick(this.container.history_id, fn);
    if (this.container_type == "sidewindow")
      app.setHistoryClick(this.container.history_id, fn);
  }

  onBeforeClose(res) {
    res();
  }
  onClose() { }

  close(...args) {
    let real_close = () => {
      app.setHistoryActive(this.container.history_id, false);
      this.container.close(...args);
      if (this.onClose) this.onClose();
      this.closed = true;
    };
    if (this.onBeforeClose) {
      // return TRUE to prevent closing
      new Promise((res, rej) => this.onBeforeClose(res, rej)).then(
        real_close,
        () => { }
      );
    } else real_close();
  }

  static closeAll(type) {
    DragBox.closeAll(type);
    Tab.closeAll(type);
    FibWindow.closeAll();
  }

  addCallback(cb_name, new_func) {
    this.container[cb_name] = new_func;
  }

  getCenter() {
    if (this.container.getCenter) return this.container.getCenter();
    return [this.width / 2, this.height / 2];
  }

  get width() {
    return this.container.width;
  }

  get height() {
    return this.container.height;
  }

  set width(v) {
    this.container.width = v;
  }

  set height(v) {
    this.container.height = v;
  }

  get bg_width() {
    if (this.container.in_background)
      return app.getElement("#bg-workspace").clientWidth;
    else return this.width;
  }

  get bg_height() {
    if (this.container.in_background)
      return app.getElement("#bg-workspace").clientHeight;
    else return this.height;
  }

  hideMenuButton() {
    if (this.container.btn_menu) this.container.btn_menu.style.display = "none";
  }

  getContent() {
    return this.container.getContent();
  }

  getContainer() {
    return this.container;
  }

  appendChild(el) {
    this.content_area.appendChild(el);
  }

  appendBackground(el) {
    if (this.container.appendBackground) this.container.appendBackground(el);
    else this.appendChild(el);
  }

  isInBackground() {
    return this.container.in_background == true;
  }

  getTitle(with_sub) {
    return this.container.getTitle(with_sub);
  }

  setTitle(val) {
    this.container.setTitle(val);
    return this;
  }

  setDefaultSize(w, h) {
    box_sizes[this.getTitle()] = [w, h];
    if (this.container_type === "dragbox") {
      this.container.setSize(w, h);
    }
  }

  setSubtitle(val) {
    if (["dragbox", "fibwindow", "sidewindow"].includes(this.container_type))
      this.container.setSubtitle(val);
    return this;
  }

  onMenuClick(e) {
    this.toggleMenu();
  }

  toggleMenu() {
    this.asset_list.classList.toggle("open");
  }

  setAssetList(list, context_menu, on_menu_click) {
    var this_ref = this;

    // clear list
    this.asset_list.innerHTML = "";

    // context menu
    var menu = new Menu();
    context_menu.forEach(function (m) {
      var item = new MenuItem(m);
      item.click = function () {
        on_menu_click(this.label, this_ref.list_value);
      };
      menu.append(item);
    });

    // add asset buttons
    for (var l = 0; l < list.length; l++) {
      let el_asset = this.app.createElement("button", "asset");
      el_asset.innerHTML = list[l];
      el_asset.onclick = function () {
        this_ref.toggleMenu();
        if (this_ref.onAssetSelect) this_ref.onAssetSelect(this.innerHTML);
      };
      el_asset.addEventListener("contextmenu", function (ev) {
        ev.preventDefault();
        menu.popup(ev.x, ev.y);
        this_ref.list_value = ev.target.innerHTML;
        return false;
      });

      this.asset_list.appendChild(el_asset);
    }
  }
}

document.addEventListener("openProject", function (e) {
  Editor.closeAll();
});
