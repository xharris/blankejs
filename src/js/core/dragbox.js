var last_box = null;
var last_box_direction = 1;

class DragBox {
	constructor (content_type) {
		this.guid = guid();
		var this_ref = this;
		this.drag_container = document.createElement("div");
		this.drag_container.classList.add("drag-container");
		this.drag_container.id = "drag-container-"+this.guid;
		this.drag_container.dataset.type = content_type;
		this.drag_container.addEventListener("click", function() {
			// reset z index of others
			app.getElements('.drag-container').forEach(function(e){
				e.style.zIndex = 10;
				e.classList.remove('focused');
			});
			// bring this one to top
			this.style.zIndex = 15;
			this.classList.add('focused');
		});
		this.drag_container.click();

		this.drag_handle = document.createElement("div");
		this.drag_handle.classList.add("drag-handle");
		this.drag_handle.id = "drag-handle-"+this.guid;
		this.drag_handle.ondblclick = function() {
			this_ref.toggleVisible();
		}
		this.drag_container.appendChild(this.drag_handle);

		this.resize_handle = document.createElement("div");
		this.resize_handle.classList.add("resize-handle");
		this.resize_handle.id = "resize-"+this.guid;
		this.drag_container.appendChild(this.resize_handle);

		this.drag_content = document.createElement("div");
		this.drag_content.classList.add("content");
		this.drag_content.id = "content-"+this.guid;
		this.drag_content.dataset.type = content_type;

		this.btn_close = document.createElement("button");
		this.btn_close.classList.add("btn-close");
		this.btn_close.innerHTML = "<i class=\"mdi mdi-close\"></i>"
		this.btn_close.onclick = function() { this_ref.close(); }
		this.drag_container.appendChild(this.btn_close);

		this.btn_menu = document.createElement("button");
		this.btn_menu.classList.add("btn-menu");
		this.btn_menu.innerHTML = "<i class=\"mdi mdi-menu\"></i>"
		this.drag_container.appendChild(this.btn_menu);

		this.drag_container.appendChild(this.drag_content);

		this.x = 0;
		this.y = 0;
		// place at an offset of the last box
		if (last_box) {
			this.x = last_box.x + (20 * last_box_direction);
			this.y = last_box.y + (20 * last_box_direction);
			last_box_direction *= -1;
		}
		// prevent from spawning box inside title bar
		if (this.y < 34) {
			this.y = 34;
		}
		
		last_box = this;

		this.setupDrag();
		this.setupResize();

	    // translate the element
	    this.move(this.x, this.y);
	}

	get width () {
		return this.drag_container.offsetWidth;
	}

	get height () {
		return this.drag_container.offsetHeight;
	}

	getContent () {
		return this.drag_container;
	}

	// focus a dragbox with a certain title if it exists
	static focus (title) {
		var handles = app.getElements('.drag-handle');
		for (var h = 0; h < handles.length; h++) {
			if (handles[h].innerHTML == title) {
				handles[h].click();
				return true;
			}
		}
		return false;
	}

	setupResize () {
		var this_ref = this;
		interact('#'+this.drag_container.id)
			.resizable({
				allowFrom: '#resize-'+this.guid,
				edges: {right:true, bottom:true, left:false, top:false},
				restictEdges: {
					outer: 'parent',
					endOnly: true,
					elementRect: { top: 34, left: 0, bottom: 23, right: 1 }
				}
			})
			.on('resizemove', function (event) {
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

				this_ref.onResize(this_ref.drag_content.offsetWidth, this_ref.drag_content.offsetHeight);
			});
	}

	move (x, y) {
        // keep the dragged position in the data-x/data-y attributes
        this.x = x;
        this.y = y;

		// translate the element
	    this.drag_container.style.webkitTransform =
	    this.drag_container.style.transform =
	      'translate(' + this.x + 'px, ' + this.y + 'px)';

	    // update the posiion attributes
	    this.drag_container.setAttribute('data-x', this.x);
	    this.drag_container.setAttribute('data-y', this.y);
	}

	setupDrag () {
		var this_ref = this;
		interact('#'+this.drag_container.id)
			.draggable({
				ignoreFrom: '#content-'+this.guid,
				inertia: true,
				restrict: {
					restriction: "parent",
					endOnly: true,
					elementRect: {top:0, left:0, bottom:1, right:1}
				},
				onmove: function(event) {
				    var target = event.target;
			        // keep the dragged position in the data-x/data-y attributes
			        this_ref.x = (parseFloat(target.getAttribute('data-x')) || 0) + event.dx;
			        this_ref.y = (parseFloat(target.getAttribute('data-y')) || 0) + event.dy;

				    this_ref.x = parseInt(this_ref.x);
				    this_ref.y = parseInt(this_ref.y);
	
					// prevent from spawning box inside title bar
					if (this_ref.y < 34) {
						this_ref.y = 34;
					}	
						    
				    // translate the element
				    target.style.webkitTransform =
				    target.style.transform =
				      'translate(' + this_ref.x + 'px, ' + this_ref.y + 'px)';

				    // update the posiion attributes
				    target.setAttribute('data-x', this_ref.x);
				    target.setAttribute('data-y', this_ref.y);
				}
			});
	}

	setTitle (value) {
		this.drag_handle.innerHTML = value;
	}

	toggleVisible () {
		this.drag_container.classList.toggle("collapsed");

		if (this.drag_container.classList.contains('collapsed')) {
			interact('#'+this.drag_container.id).unset();
			this.setupDrag();
		} else {
			this.setupResize();
		}
	}

	appendTo (element) {
		element.appendChild(this.drag_container);
	}

	onResize (w, h) {

	}

	set width(w) {
		this.drag_container.style.width = w.toString()+"px";
	}

	set height(h) {
		this.drag_container.style.height = h.toString()+"px";
	}

	setContent (element) {
		this.drag_content.innerHTML = "";
		this.drag_content.appendChild(element);
	}

	appendChild (element) {
		this.drag_content.appendChild(element);
	}

	close () {
		this.drag_container.remove();
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
}