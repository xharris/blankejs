var boxes = [];

class FibWindow {
	constructor (content_type) {
		this.guid = guid();

		console.log ("ehoo")
		this.title = '';
		this.subtitle = '';

		var this_ref = this;
		this.history_id = app.addHistory(this.title);

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
		this.fib_title.classList.add("title");

		this.btn_close = document.createElement("button");
		this.btn_close.classList.add("btn-close");
		this.btn_close.innerHTML = "<i class=\"mdi mdi-close\"></i>"
		this.btn_close.onclick = function() { this_ref.close(); }
		this.fib_container.appendChild(this.btn_close);

		this.btn_menu = document.createElement("button");
		this.btn_menu.classList.add("btn-menu");
		this.btn_menu.innerHTML = "<i class=\"mdi mdi-menu\"></i>"
		this.fib_container.appendChild(this.btn_menu);

		this.x = 0;
		this.y = 0;

		boxes.unshift(this);
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

	// focus a dragbox with a certain title if it exists
	static focus (title) {
		DragBox.showAll();
		var handles = app.getElements('.drag-handle');
		for (var h = 0; h < handles.length; h++) {
			if (handles[h].innerHTML == title) {
				handles[h].click();
				return true;
			}
		}
		return false;
	}

	static resizeWindows () {
		for (let b = 0; b < boxes.length; b++) {
			let box_ref = boxes[b];

			// resize
		    var target = event.target;
	        this_ref.x = (parseFloat(target.getAttribute('data-x')) || 0);
	        this_ref.y = (parseFloat(target.getAttribute('data-y')) || 0);

		    // update the element's style
		    target.style.width  = event.rect.width + 'px';
		    target.style.height = event.rect.height + 'px';

		    // translate when resizing from top or left edges
		    this_ref.x += event.deltaRect.left;
		    this_ref.y += event.deltaRect.top;

		    this_ref.x = parseInt(this_ref.x);
		    this_ref.y = parseInt(this_ref.y);

		    target.style.webkitTransform = target.style.transform =
		        'translate(' + this_ref.x + 'px,' + this_ref.y + 'px)';

		    target.setAttribute('data-x', this_ref.x);
		    target.setAttribute('data-y', this_ref.y);

			// move
	        // keep the dragged position in the data-x/data-y attributes
	        this.x = x;
	        this.y = y;

			// translate the element
		    this.fib_container.style.webkitTransform =
		    this.fib_container.style.transform =
		      'translate(' + this.x + 'px, ' + this.y + 'px)';

		    // update the posiion attributes
		    this.fib_container.setAttribute('data-x', this.x);
		    this.fib_container.setAttribute('data-y', this.y);

			box_ref.onResize(this_ref.drag_content.offsetWidth, this_ref.drag_content.offsetHeight);
		}
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
		this.fib_container.innerHTML = "";
		this.fib_container.appendChild(element);
	}

	appendChild (element) {
		this.fib_container.appendChild(element);
	}

	close () {
		this.fib_container.remove();
		if (this.onClose) this.onClose();
	}

	static closeAll (type) {
		var windows = app.getElements(".drag-container");
		for (var i = 0; i < windows.length; i++) {
			if (!type || (type && windows[i].dataset.type == type))
				windows[i].remove();
		}
	}

	static showHideAll () {
		var windows = app.getElements(".drag-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].classList.toggle("invisible");
		}
	}

	static showAll () {
		var windows = app.getElements(".drag-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].classList.remove("invisible");
		}
	}

	static hideAll () {	
		var windows = app.getElements(".drag-container");
		for (var i = 0; i < windows.length; i++) {
			windows[i].classList.add("invisible");
		}
	}
}