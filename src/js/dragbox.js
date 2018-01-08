class DragBox {
	constructor (content_type) {
		this.guid = guid();
		var this_ref = this;

		this.drag_container = document.createElement("div");
		this.drag_container.classList.add("drag-container");
		this.drag_container.id = "drag-container-"+this.guid;
		this.drag_container.addEventListener("click", function() {
			// reset z index of others
			app.getElements('.drag-container').forEach(function(e){
				e.style.zIndex = 10;
			});
			// bring this one to top
			this.style.zIndex = 15;
		});

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

		var x = 0, y = 0;

		interact('#'+this.drag_container.id)
			.draggable({
				allowFrom: '#drag-handle-'+this.guid,
				inertia: false,
				restrict: {
					restriction: "parent",
					endOnly: true,
					elementRect: {top:0, left:0, bottom:1, right:1}
				},
				onmove: function(event) {
				    var target = event.target,
			        // keep the dragged position in the data-x/data-y attributes
			        x = (parseFloat(target.getAttribute('data-x')) || 0) + event.dx,
			        y = (parseFloat(target.getAttribute('data-y')) || 0) + event.dy;

				    // translate the element
				    target.style.webkitTransform =
				    target.style.transform =
				      'translate(' + x + 'px, ' + y + 'px)';

				    // update the posiion attributes
				    target.setAttribute('data-x', x);
				    target.setAttribute('data-y', y);
				}
			})
			.resizable({
				allowFrom: '#resize-'+this.guid,
				edges: {left:false, right:true, bottom:true, top:false},
				restictEdges: {
					outer: 'parent',
					endOnly: true
				}
			})
			.on('resizemove', function (event) {
			    var target = event.target,
			        x = (parseFloat(target.getAttribute('data-x')) || 0),
			        y = (parseFloat(target.getAttribute('data-y')) || 0);

			    // update the element's style
			    target.style.width  = event.rect.width + 'px';
			    target.style.height = event.rect.height + 'px';

			    // translate when resizing from top or left edges
			    x += event.deltaRect.left;
			    y += event.deltaRect.top;

			    target.style.webkitTransform = target.style.transform =
			        'translate(' + x + 'px,' + y + 'px)';

			    target.setAttribute('data-x', x);
			    target.setAttribute('data-y', y);
			});
	}

	setTitle (value) {
		this.drag_handle.innerHTML = value;
	}

	toggleVisible () {
		this.drag_container.classList.toggle("collapsed");
	}

	appendTo (element) {
		element.appendChild(this.drag_container);
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
	}
}