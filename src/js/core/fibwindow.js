var boxes = [];
var split_enabled = true;
var SHOW_SINGLE_BOX_TITLEBAR = true;

class FibWindow {
	constructor(content_type) {
		this.guid = guid();

		this.title = '';
		this.subtitle = '';
		this.history_id = app.addHistory(this.title);
		this.type = content_type;
		this.bg_first_only = false;

		var this_ref = this;

		this.fib_container = document.createElement("div");
		this.fib_container.classList.add("fib-container");
		this.fib_container.id = "fib-container-" + this.guid;
		this.fib_container.dataset.type = content_type;
		this.fib_container.this_ref = this;
		this.fib_container.addEventListener("click", function () {
			// reset z index of others
			app.getElements('.fib-container').forEach(function (e) {
				//e.style.zIndex = 10;
				e.classList.remove('focused');
			});
			// bring this one to top
			//this.style.zIndex = 15;
			this.classList.add('focused');
		});

		this.fib_container.addEventListener("transitionend", this.callResize.bind(this));
		// this.fib_container.addEventListener('resize', this.callResize.bind(this));

		this.resize_observer = new ResizeObserver(e => {
			if (this.onResize)
				this.onResize(this.width, this.height)
		})
		this.resize_observer.observe(this.fib_container)

		this.fib_title = document.createElement("div");
		this.fib_title.classList.add("fib-title");
		this.fib_title.ondblclick = function () {
			this_ref.focus();
		}
		this.fib_title_container = app.createElement("div", "fib-title-container");
		this.fib_title_container.appendChild(this.fib_title);
		this.fib_container.appendChild(this.fib_title_container);

		this.fib_content = document.createElement("div");
		this.fib_content.classList.add("content");
		this.fib_content.dataset.type = content_type;

		this.btn_close = document.createElement("button");
		this.btn_close.classList.add("btn-close");
		this.btn_close.innerHTML = "<i class=\"mdi mdi-close\"></i>"
		this.btn_close.onclick = function () { this_ref.close(); }
		this.fib_container.appendChild(this.btn_close);

		this.btn_menu = document.createElement("button");
		this.btn_menu.classList.add("btn-menu");
		this.btn_menu.innerHTML = "<i class=\"mdi mdi-menu\"></i>"
		this.fib_container.appendChild(this.btn_menu);

		this.fib_container.appendChild(this.fib_content);

		boxes.unshift(this);

		FibWindow.resizeWindows();
		FibWindow.checkBackground();
	}

	// mainly for boxes with bg_content
	// 0 - full window, 1 - half-window
	getSizeType() {
		if (!split_enabled) return 0;
		if (this.index == 0)
			return boxes.length == 1 ? 0 : 1;
		return 0;
	}

	// returns [x,y]
	getCenter() {
		if (this.getSizeType() == 1) // half-window
			return [this.bg_content.clientWidth / 4, this.bg_content.clientHeight / 2];
		// full window, quarter
		return [this.bg_content.clientWidth / 2, this.bg_content.clientHeight / 2];
	}

	callResize() {
		blanke.cooldownFn('scene-resize-' + this.guid, 100, () => {
			this.onResize(this.fib_content.offsetWidth, this.fib_content.offsetHeight);
		});
	}

	get width() {
		return this.fib_container.offsetWidth;
	}

	get height() {
		return this.fib_container.offsetHeight;
	}

	focus() {
		FibWindow.focus(this.title);
	}

	// only returns a list of all the window titles
	static getWindowList() {
		let titles = [];
		let el_windows = blanke.getElements(".fib-title");
		for (let w = 0; w < el_windows.length; w++) { titles.push(el_windows[w].innerHTML); }
		return titles;
	}

	// focus a fibwindow with a certain title if it exists
	static focus(title) {
		FibWindow.showAll();

		for (var b = 0; b < boxes.length; b++) {
			if (boxes[b].title == title) {
				app.refreshQuickAccess(title);
				boxes[b].fib_title.click();
				boxes.unshift(boxes.splice(b, 1)[0]);
				FibWindow.resizeWindows();
				FibWindow.checkBackground();
				boxes[0]._onFocus();

				return true;
			}
		}
		return false;
	}

	static isOpen(title) {
		for (var b = 0; b < boxes.length; b++) {
			if (boxes[b].title == title) {
				return true;
			}
		}
	}

	// only show the first window and not the split screens
	static toggleSplit() {
		split_enabled = !split_enabled;
		this.resizeWindows();
		this.checkBackground();
	}

	static refreshBadgeNum() {
		app.setBadgeNum("#fibwindow-badge", boxes.length);
	}

	static resizeWindows() {
		let x = 0, y = 0, width = 50, height = 100;

		// more than max allowed fibwindows?
		if (boxes.length > app.ideSetting("max_windows")) {
			// remove oldest one
			let killed_box = boxes.pop();
			killed_box.close();
		}

		if (boxes.length == 1) width = 100;

		for (let b = 0; b < boxes.length; b++) {
			let box_ref = boxes[b];
			box_ref.index = b;
			box_ref.fib_container.dataset.index = b.toString();

			let b2 = b + 1;

			if (b2 < boxes.length || b2 % 2 == 0) {
				if (b2 % 2 == 0) x += 100;
				else x *= 2;
			}

			if (b2 < boxes.length || b2 % 2 != 0) {
				if (b2 % 2 != 0 && b2 >= 3) y += 100;
				else y *= 2;
			}

			// don't show header if it's the only window showing
			if ((boxes.length == 1 && !SHOW_SINGLE_BOX_TITLEBAR) || !split_enabled) {
				box_ref.fib_container.classList.add("no-split");
			} else {
				box_ref.fib_container.classList.remove("no-split");
			}

			box_ref.fib_container.classList.remove("invisible");
			box_ref.fib_container.style.webkitTransform = "translate(" + x + "%, " + y + "%)";

			box_ref.fib_container.style.width = width + '%';
			box_ref.fib_container.style.height = height + '%';

			if (!split_enabled) {
				if (b == 0) {
					box_ref.fib_container.classList.remove("invisible");

				} else {
					box_ref.fib_container.classList.add("invisible");

				}

			}

			if (split_enabled) {
				if (b2 % 2 == 0) {
					if (b2 < boxes.length - 1) width /= 2;
				} else {
					if (b2 < boxes.length - 1) height /= 2;
				}
			}
		}

		// update the history bar
		if (boxes.length > 0 && boxes[0].history_id) app.setHistoryMostRecent(boxes[0].history_id);
		FibWindow.refreshBadgeNum();
	}

	getTitle(with_sub) {
		return (with_sub ? this.title + this.subtitle : this.title);
	}

	setTitle(value) {
		if (this.fib_title.innerHTML != value + this.subtitle) {
			this.fib_title.innerHTML = value + this.subtitle;
			this.title = value;


			app.setHistoryText(this.history_id, this.title);
		}
	}

	setSubtitle(value) {
		this.subtitle = value || '';
		this.setTitle(this.title);
	}

	appendTo(element) {
		element.appendChild(this.fib_container);
	}

	onResize(w, h) {

	}

	getContent() {
		return this.fib_content
	}

	setContent(element) {
		this.fib_content.innerHTML = "";
		this.fib_content.appendChild(element);
	}

	appendChild(element) {
		this.fib_content.appendChild(element);
	}

	// NOTE: add background element last
	appendBackground(element) {
		this.bg_content = element;
		FibWindow.checkBackground();
	}

	// which fibwindow should have content in the background
	static checkBackground() {
		let el_bg_workspace = app.getElement('#bg-workspace');
		let el_workspace = app.getElement('#workspace');

		let first_box = boxes[0];
		// remove class from other boxes NOTE!!! This loops iterates 1 -> boxes.length
		let old_first_found = false;
		for (let b = 1; b < boxes.length; b++) {
			if (boxes.length != 1 && split_enabled)
				boxes[b].fib_container.classList.remove("single");
			if (first_box.guid != boxes[b].guid) {
				boxes[b].fib_container.classList.remove("first");
				if (boxes[b].bg_content && boxes[b].in_background) {
					old_first_found = true;
					if (!boxes[b].bg_first_only) {
						if (el_bg_workspace.contains(boxes[b].bg_content)) {
							boxes[b].resize_observer.unobserve(el_bg_workspace);
							el_bg_workspace.removeChild(boxes[b].bg_content)
						}
						boxes[b].appendChild(boxes[b].bg_content)
					}
				}
				boxes[b].in_background = false;
			}
		}
		if (!old_first_found) {
			blanke.clearElement(el_bg_workspace);
			el_bg_workspace.focused_guid = '';
		}

		// set up the first box
		if (first_box) {
			first_box.fib_container.classList.remove("single");

			if (boxes.length == 1 || !split_enabled) {
				first_box.fib_container.classList.add("single");
				first_box.fib_container.classList.add('focused');
			}
			if (first_box.bg_content &&
				(!first_box.in_background || el_bg_workspace.focused_guid != first_box.guid)) {
				blanke.clearElement(el_bg_workspace);
				first_box.in_background = true;
				first_box.fib_container.classList.add("first");
				el_bg_workspace.dataset.type = first_box.type;
				el_bg_workspace.focused_guid = first_box.guid;
				el_bg_workspace.appendChild(first_box.bg_content);
				first_box.resize_observer.observe(el_bg_workspace)

				if (el_bg_workspace.childElementCount > 0)
					el_workspace.dataset.bgType = first_box.type;
			}
		}

		if (el_bg_workspace.childElementCount == 0)
			el_workspace.dataset.bgType = null;

		if (boxes[0])
			boxes[0]._onFocus();
	}

	_onFocus() {
		if (this.onFocus) {// TODO: don't focus if already focused
			this.onFocus();
		}
		this.focused = true;
		for (var b = 0; b < boxes.length; b++) {
			if (boxes[b].title != this.title) {
				boxes[b].focused = false;
			}
		}
	}

	close(remove_history) {
		let real_close = () => {
			this.fib_container.remove();

			if (this.onClose) remove_history = ifndef(this.onClose(), remove_history);

			for (let b = 0; b < boxes.length; b++) {
				if (boxes[b].history_id == this.history_id) {
					boxes.splice(b, 1);
				}
			}
			FibWindow.resizeWindows();
			FibWindow.checkBackground();

			if (remove_history)
				app.removeHistory(this.history_id);
			else
				app.setHistoryActive(this.history_id, false);
		}
		if (this.onBeforeClose) { // return TRUE to prevent closing
			(new Promise((res, rej) => this.onBeforeClose(res, rej))).then(real_close, () => { })
		} else
			real_close();
	}

	static closeAll(type) {
		var windows = app.getElements(".fib-container");
		for (var i = 0; i < windows.length; i++) {
			if (!type || (type && windows[i].dataset.type == type))
				windows[i].remove();
		}
		blanke.clearElement(app.getElement("#bg-workspace"));
		boxes = [];
	}

	static showHideAll() {
		var windows = app.getElements(".fib-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].classList.toggle("invisible");
		}
	}

	static showAll() {
		var windows = app.getElements(".fib-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].classList.remove("invisible");
		}
	}

	static hideAll() {
		var windows = app.getElements(".fib-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].classList.add("invisible");
		}
	}
}