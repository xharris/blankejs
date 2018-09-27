var boxes = [];
var MAX_WINDOWS = 5;

class FibWindow {
	constructor (content_type) {
		this.guid = guid();

		this.title = '';
		this.subtitle = '';

		var this_ref = this;

		this.fib_container = document.createElement("div");
		this.fib_container.classList.add("fib-container");
		this.fib_container.id = "fib-container-"+this.guid;
		this.fib_container.dataset.type = content_type;
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

	get width () {
		return this.fib_container.offsetWidth;
	}

	get height () {
		return this.fib_container.offsetHeight;
	}

	getContent () {
		return this.fib_container;
	}

	focus () {
		FibWindow.focus(this.title);
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

			box_ref.fib_container.style.left = x+"%";
			box_ref.fib_container.style.top = y+"%";
			box_ref.fib_container.style.width = width+'%';
			box_ref.fib_container.style.height = height+'%';

			box_ref.onResize(box_ref.fib_content.offsetWidth, box_ref.fib_content.offsetHeight);		
		
			if ((b+1) % 2 == 0) {
				if (b < boxes.length - 2) width /= 2;
				y += height;
			} else {
				if (b < boxes.length - 2) height /= 2;
				x += width;
			}
		}
	}

	setTitle (value) {
		if (this.fib_title.innerHTML != value+this.subtitle) {
			this.fib_title.innerHTML = value+this.subtitle;
			this.title = value;

			if (!this.history_id) this.history_id = app.addHistory(this.title);
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

	close () {
		this.fib_container.remove();
		if (this.onClose) this.onClose();
		for (let b = 0; b < boxes.length; b++) {
			if (boxes[b].history_id == this.history_id) {
				boxes.splice(b,1);
			}
		}
		FibWindow.resizeWindows();
	}

	static closeAll (type) {
		var windows = app.getElements(".fib-container");
		for (var i = 0; i < windows.length; i++) {
			if (!type || (type && windows[i].dataset.type == type))
				windows[i].remove();
		}
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