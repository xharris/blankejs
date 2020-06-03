const interact = require('interactjs')

var last_box = null;
let snap = 16;
var last_box_direction = 1;
var box_sizes = {};

class DragBox {
  constructor(content_type) {
    this.guid = guid();

    this.title = "";
    this.subtitle = "";
    this.fresh_box = true;

    var this_ref = this;
    this.history_id = app.addHistory(this.title);

    app.setHistoryClick(this.history_id, function () {
      this_ref.focus();
    });

    this.drag_container = document.createElement("div");
    this.drag_container.this_ref = this
    this.drag_container.classList.add("drag-container");
    this.drag_container.id = "drag-container-" + this.guid;
    this.drag_container.dataset.type = content_type;
    this.drag_container.addEventListener("click", function () {
      // reset z index of others
      app.getElements(".drag-container").forEach(function (e) {
        e.style.zIndex = 10;
        e.classList.remove("focused");
      });
      // bring this one to top
      this.style.zIndex = 15;
      this.classList.add("focused");
    });
    this.drag_container.click();

    this.drag_handle = document.createElement("div");
    this.drag_handle.classList.add("drag-handle");
    this.drag_handle.id = "drag-handle-" + this.guid;
    this.drag_handle.ondblclick = function () {
      this_ref.toggleVisible();
    };
    this.drag_container.appendChild(this.drag_handle);

    this.resize_handle = document.createElement("div");
    this.resize_handle.classList.add("resize-handle");
    this.resize_handle.id = "resize-" + this.guid;
    this.drag_container.appendChild(this.resize_handle);

    this.drag_content = document.createElement("div");
    this.drag_content.classList.add("content");
    this.drag_content.id = "content-" + this.guid;
    this.drag_content.dataset.type = content_type;

    this.btn_close = document.createElement("button");
    this.btn_close.classList.add("btn-close");
    this.btn_close.innerHTML = '<i class="mdi mdi-close"></i>';
    this.btn_close.onclick = function () {
      this_ref.close();
    };
    this.drag_container.appendChild(this.btn_close);

    this.btn_menu = document.createElement("button");
    this.btn_menu.classList.add("btn-menu");
    this.btn_menu.innerHTML = '<i class="mdi mdi-menu"></i>';
    this.drag_container.appendChild(this.btn_menu);

    this.drag_container.appendChild(this.drag_content);

    this.x = 0;
    this.y = 0;
    this.old_x = 0;
    this.old_y = 0;
    // place at an offset of the last box
    if (last_box) {
      let size = app.size;
      this.x = last_box.x + 20 * last_box_direction;
      this.y = last_box.y + 20 * last_box_direction;
      // box position constraints
      if (last_box.x < 0) last_box.x = 0;
      if (last_box.y < 34) last_box.y = 34;
      if (size[0] > last_box.x) last_box.x = 0;
      if (size[1] > last_box.y) last_box.y = 34;
      last_box_direction *= -1;
    }

    last_box = this;

    this.setupDrag();
    this.setupResize();

    // translate the element
    this.move(this.x, this.y);
  }

  get width() {
    return this.drag_container.offsetWidth;
  }

  get height() {
    return this.drag_container.offsetHeight;
  }

  getContent() {
    return this.drag_container;
  }

  focus() {
    let val = DragBox.focus(this.title);
    if (val !== false && val !== true) this.history_id = val;
  }

  // focus a dragbox with a certain title if it exists
  static focus(title, no_history) {
    DragBox.showAll();
    var handles = app.getElements(".drag-handle");
    for (var h = 0; h < handles.length; h++) {
      if (handles[h].innerHTML == title) {
        app.refreshQuickAccess(title);
        handles[h].click();
        if (!no_history) return app.addHistory(title);
        else return true;
      }
    }
    return false;
  }

  setupResize() {
    var this_ref = this;
    interact("#" + this.drag_container.id)
      .resizable({
        allowFrom: "#resize-" + this.guid,
        edges: { right: true, bottom: true, left: false, top: false },
        restictEdges: {
          outer: "parent",
          endOnly: true,
          elementRect: { top: 0, left: 0, bottom: 23, right: 1 },
        },
      })
      .on("resizemove", event => {
        var target = event.target;
        this_ref.x = parseFloat(target.getAttribute("data-x")) || 0;
        this_ref.y = parseFloat(target.getAttribute("data-y")) || 0;

        // update the element's style
        // target.style.width  = event.rect.width + 'px';
        // target.style.height = event.rect.height + 'px';
        this.setSize(event.rect.width, event.rect.height);

        // translate when resizing from top or left edges
        this_ref.x += event.deltaRect.left;
        this_ref.y += event.deltaRect.top;

        this_ref.x = parseInt(this_ref.x);
        this_ref.y = parseInt(this_ref.y);

        target.style.webkitTransform = target.style.transform =
          "translate(" + this_ref.x + "px," + this_ref.y + "px)";

        target.setAttribute("data-x", this_ref.x);
        target.setAttribute("data-y", this_ref.y);
      })
      .on("resizeend", e => {
        let width = parseInt(e.target.style.width);
        let height = parseInt(e.target.style.height);
        //width = width - (width % snap);
        //height = height - ((height) % snap);

        this.setSize(width, height);

        // app.flashCrosshair(this_ref.x + width, this_ref.y + height);

        this_ref.fresh_box = false;
        this_ref.onResize(
          this_ref.drag_content.offsetWidth,
          this_ref.drag_content.offsetHeight
        );
        box_sizes[this_ref.title] = [
          this_ref.drag_content.offsetWidth,
          this_ref.drag_content.offsetHeight,
        ];
      });
  }

  move(x, y) {
    // keep the dragged position in the data-x/data-y attributes
    this.x = x;
    this.y = y;

    // translate the element
    this.drag_container.style.webkitTransform = this.drag_container.style.transform =
      "translate(" + this.x + "px, " + this.y + "px)";

    // update the posiion attributes
    this.drag_container.setAttribute("data-x", this.x);
    this.drag_container.setAttribute("data-y", this.y);
  }

  setupDrag() {
    var this_ref = this;

    interact("#" + this.drag_container.id).draggable({
      ignoreFrom: "#content-" + this.guid,
      inertia: true,
      restrict: {
        restriction: "parent",
        endOnly: true,
        elementRect: { top: 0, left: 0, bottom: 1, right: 1 },
      },
      onmove: function (event) {
        var target = event.target;
        // keep the dragged position in the data-x/data-y attributes
        this_ref.x =
          (parseFloat(target.getAttribute("data-x")) || 0) + event.dx;
        this_ref.y =
          (parseFloat(target.getAttribute("data-y")) || 0) + event.dy;

        this_ref.x = parseInt(this_ref.x);
        this_ref.y = parseInt(this_ref.y);

        // translate the element
        target.style.webkitTransform = target.style.transform =
          "translate(" + this_ref.x + "px, " + this_ref.y + "px)";

        // update the posiion attributes
        target.setAttribute("data-x", this_ref.x);
        target.setAttribute("data-y", this_ref.y);
      },
      onend: function (e) {
        let x = this_ref.x; // - (this_ref.x % snap);
        let y = this_ref.y; // - (this_ref.y % snap);

        e.target.style.webkitTransform = e.target.style.transform =
          "translate(" + x + "px, " + y + "px)";
        e.target.setAttribute("data-x", x);
        e.target.setAttribute("data-y", y);

        app.flashCrosshair(x, y);
      },
    });
  }

  getTitle(with_sub) {
    return with_sub ? this.title + this.subtitle : this.title;
  }

  setTitle(value) {
    if (this.drag_handle.innerHTML != value + this.subtitle) {
      this.drag_handle.innerHTML = value + this.subtitle;
      this.title = value;
      if (box_sizes[value] && this.fresh_box) {
        this.setSize(box_sizes[value][0], box_sizes[value][1]);
        this.fresh_box = false;
      } else {
        box_sizes[value] = [
          this.drag_container.offsetWidth,
          this.drag_container.offsetHeight,
        ];
      }
      app.setHistoryText(this.history_id, this.title);
    }
  }

  setSize(w, h) {
    if (w) {
      this.drag_container.style.width = w + "px";
      // this.drag_container.style.minWidth = w+"px";
      // this.drag_container.style.maxWidth = w+"px";
    }
    if (h) {
      this.drag_container.style.height = h + "px";
      // this.drag_container.style.minHeight = h+"px";
      // this.drag_container.style.maxHeight = h+"px";
    }
  }

  setSubtitle(value) {
    this.subtitle = value || "";
    this.setTitle(this.title);
  }

  toggleVisible() {
    this.drag_container.classList.toggle("collapsed");

    if (this.drag_container.classList.contains("collapsed")) {
      // save position
      this.old_x = this.x;
      this.old_y = this.y;
      this.move(0, 0);
      // move dragbox to "sidebar"
      interact("#" + this.drag_container.id).unset();
      app.getElement("#workspace").removeChild(this.drag_container);
      this.appendTo(app.getElement("#sidebar"));
    } else {
      // move dragbox out of "sidebar" and restore interaction
      app.getElement("#sidebar").removeChild(this.drag_container);
      this.appendTo(app.getElement("#workspace"));
      this.setupDrag();
      this.setupResize();
      // restore position
      this.move(this.old_x, this.old_y);
    }
  }

  appendTo(element) {
    element.appendChild(this.drag_container);
    DragBox.refreshBadgeNum();
  }

  onResize(w, h) { }

  set width(w) {
    this.setSize(w, null);
  }

  set height(h) {
    this.setSize(null, h);
  }

  setContent(element) {
    this.drag_content.innerHTML = "";
    this.drag_content.appendChild(element);
  }

  appendChild(element) {
    this.drag_content.appendChild(element);
  }

  close() {
    this.drag_container.remove();
    if (this.onClose) this.onClose();
    DragBox.refreshBadgeNum();
  }

  static refreshBadgeNum() {
    var windows = app.getElements(".drag-container");
    app.setBadgeNum("#dragbox-badge", windows.length);
  }

  static closeAll(type) {
    var windows = app.getElements(".drag-container");
    for (var i = 0; i < windows.length; i++) {
      if (!type || (type && windows[i].dataset.type == type))
        windows[i].remove();
    }
  }

  static showHideAll() {
    var windows = app.getElements(".drag-container");
    for (var i = 0; i < windows.length; i++) {
      windows[i].classList.toggle("invisible");
    }
  }

  static showAll() {
    var windows = app.getElements(".drag-container");
    for (var i = 0; i < windows.length; i++) {
      windows[i].classList.remove("invisible");
    }
  }

  static hideAll() {
    var windows = app.getElements(".drag-container");
    for (var i = 0; i < windows.length; i++) {
      windows[i].classList.add("invisible");
    }
  }
}

document.addEventListener("ideReady", e => {
  let resize_timeout

  app.window.on("resize", e => {
    if (resize_timeout)
      clearTimeout(resize_timeout)
    resize_timeout = setTimeout(() => {
      // check if elements are outside of window 
      const parent = app.getElement("#workspace")
      const parent_rect = parent.getBoundingClientRect()
      app.getElements(".drag-container").forEach(el => {
        const rect = {
          x: el.this_ref.x, y: el.this_ref.y,
          width: el.clientWidth, height: el.clientHeight
        }

        let new_left = el.this_ref.x, new_top = el.this_ref.y

        // right
        if (new_left + rect.width > parent_rect.width)
          new_left = parent_rect.width - rect.width

        // bottom
        if (new_top + rect.height > parent_rect.height)
          new_top = parent_rect.height - rect.height

        // top 
        if (new_left < parent_rect.x)
          new_left = 0

        // left 
        if (new_top < parent_rect.y)
          new_top = 0

        el.this_ref.move(new_left, new_top)
      })
    }, 1000)
  })
})