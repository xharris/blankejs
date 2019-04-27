var boxes = [];
var MAX_WINDOWS = 10; //5;
var split_enabled = true;
var SHOW_SINGLE_BOX_TITLEBAR = true;

class FibWindow {
	constructor (content_type) {
		this.guid = guid();

		this.title = '';
		this.subtitle = '';
		this.history_id = app.addHistory(this.title);

		var this_ref = this;

		this.fib_container = document.createElement("div");
		this.fib_container.classList.add("fib-container");
		this.fib_container.id = "fib-container-"+this.guid;
		this.fib_container.dataset.type = content_type;
		this.fib_container.this_ref = this;
		this.fib_container.addEventListener("click", function() {
			// reset z index of others
			app.getElements('.fib-container').forEach(function(e){
				//e.style.zIndex = 10;
				e.classList.remove('focused');
			});
			// bring this one to top
			//this.style.zIndex = 15;
			this.classList.add('focused');
		});

		this.fib_container.addEventListener("transitionend", this.callResize.bind(this));
		window.addEventListener('resize', this.callResize.bind(this));

		this.fib_title = document.createElement("div");
		this.fib_title.classList.add("fib-title");
		this.fib_title.ondblclick = function() {
			this_ref.focus();
		}
		this.fib_container.appendChild(this.fib_title);

		this.fib_content = document.createElement("div");
		this.fib_content.classList.add("content");
		this.fib_content.dataset.type = content_type;

		this.btn_close = document.createElement("button");
		this.btn_close.classList.add("btn-close");
		this.btn_close.innerHTML = "<i class=\"mdi mdi-close\"></i>"
		this.btn_close.onclick = function() { this_ref.close(); }
		this.fib_container.appendChild(this.btn_close);

		this.btn_menu = document.createElement("button");
		this.btn_menu.classList.add("btn-menu");
		this.btn_menu.innerHTML = "<i class=\"mdi mdi-menu\"></i>"
		this.fib_container.appendChild(this.btn_menu);

		this.fib_container.appendChild(this.fib_content);

		boxes.unshift(this);

		FibWindow.resizeWindows();
	}

	callResize () {
		let this_ref = this;
		blanke.cooldownFn('scene-resize-'+this.guid, 100, function(){	
			this_ref.onResize(this_ref.fib_content.offsetWidth, this_ref.fib_content.offsetHeight);
		});
	}

	get width () {
		return this.fib_container.offsetWidth;
	}

	get height () {
		return this.fib_container.offsetHeight;
	}

	focus () {
		FibWindow.focus(this.title);
	}	

	// only returns a list of all the window titles
	static getWindowList () {
		let titles = [];
		let el_windows = blanke.getElements(".fib-title");
		for (let w = 0; w < el_windows.length; w++) { titles.push(el_windows[w].innerHTML); }
		return titles;
	}

	// focus a fibwindow with a certain title if it exists
	static focus (title) {
		FibWindow.showAll();

		for (var b = 0; b < boxes.length; b++) {
			if (boxes[b].title == title) {
				boxes[b].fib_title.click();
				boxes.unshift(boxes.splice(b,1)[0]);
				FibWindow.resizeWindows();

				return true;
			}
		}
		return false;
	}

	// only show the first window and not the split screens
	static toggleSplit () {
		split_enabled = !split_enabled;
		this.resizeWindows();
	}

	static refreshBadgeNum () {
		app.setBadgeNum("#fibwindow-badge", boxes.length);
	}

	static resizeWindows () {
		let x = 0, y = 0, width = 50, height = 100;

		// more than max allowed fibwindows?
		if (boxes.length > MAX_WINDOWS) {
			// remove oldest one
			let killed_box = boxes.pop();
			killed_box.close();
		}

		if (boxes.length == 1) width = 100;

		for (let b = 0; b < boxes.length; b++) {
			let box_ref = boxes[b];

			let b2 = b+1;

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

			if (split_enabled) {
				box_ref.fib_container.classList.remove("invisible");
				box_ref.fib_container.style.webkitTransform = "translate("+x+"%, "+y+"%)";

				box_ref.fib_container.style.width = width+'%';
				box_ref.fib_container.style.height = height+'%';

			} else {
				if (b == 0) {
					box_ref.fib_container.classList.remove("invisible");

				} else {
					box_ref.fib_container.classList.add("invisible");

				}

			}
			
			if (b2 % 2 == 0) {
				if (b2 < boxes.length - 1) width /= 2;
			} else {
				if (b2 < boxes.length - 1) height /= 2;
			}
		}

		// update the history bar
		if (boxes.length > 0 && boxes[0].history_id) app.setHistoryMostRecent(boxes[0].history_id);
		FibWindow.refreshBadgeNum();
	}

	setTitle (value) {
		if (this.fib_title.innerHTML != value+this.subtitle) {
			this.fib_title.innerHTML = value+this.subtitle;
			this.title = value;

			
			app.setHistoryText(this.history_id, this.title);
		}
	}

	setSubtitle (value) {
		this.subtitle = value || '';
		this.setTitle(this.title);
	}

	appendTo (element) {
		element.appendChild(this.fib_container);
	}

	onResize (w, h) {

	}

	setContent (element) {
		this.fib_content.innerHTML = "";
		this.fib_content.appendChild(element);
	}

	appendChild (element) {
		this.fib_content.appendChild(element);
	}

	close (remove_history) {
		this.fib_container.remove();

		if (this.onClose) remove_history = ifndef(this.onClose(), remove_history);
		for (let b = 0; b < boxes.length; b++) {
			if (boxes[b].history_id == this.history_id) {
				boxes.splice(b,1);
			}
		}
		FibWindow.resizeWindows();

		if (remove_history)
			app.removeHistory(this.history_id);
		else
			app.setHistoryActive(this.history_id, false);
	}

	static closeAll (type) {
		var windows = app.getElements(".fib-container");
		for (var i = 0; i < windows.length; i++) {
			if (!type || (type && windows[i].dataset.type == type))
				windows[i].remove();
		}
		boxes = [];
	}

	static showHideAll () {
		var windows = app.getElements(".fib-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].classList.toggle("invisible");
		}
	}

	static showAll () {
		var windows = app.getElements(".fib-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].classList.remove("invisible");
		}
	}

	static hideAll () {	
		var windows = app.getElements(".fib-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].classList.add("invisible");
		}
	}
}