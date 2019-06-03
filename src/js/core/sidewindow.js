var instances = [];
var curr_category = '';
var MAX_WINDOWS = 10; //5;

class SideWindow {
	constructor (content_type) {
		this.guid = guid();
		this.history_id = app.addHistory(this.title);
		this.title = '';
		this.subtitle = '';

		var this_ref = this;

		this.el_container = document.createElement("div");
		this.el_container.classList.add("sidewin");
		this.el_container.id = "sidewin-"+this.guid;
		this.el_container.dataset.type = content_type;
		this.el_container.this_ref = this;
		this.el_container.addEventListener("click", function() {
			app.getElements('.sidewin').forEach(function(e){
				e.classList.remove('focused');
			});
			this.classList.add('focused');
		});

		this.el_container.addEventListener("transitionend", this.callResize.bind(this));
		window.addEventListener('resize', this.callResize.bind(this));

		this.el_title = document.createElement("div");
		this.el_title.classList.add("sidewin-title");
		this.el_title.ondblclick = function() {
			this_ref.focus();
		}
		this.el_container.appendChild(this.el_title);

		this.el_content = document.createElement("div");
		this.el_content.classList.add("content");
		this.el_content.dataset.type = content_type;

		this.btn_close = document.createElement("button");
		this.btn_close.classList.add("btn-close");
		this.btn_close.innerHTML = "<i class=\"mdi mdi-close\"></i>"
		this.btn_close.onclick = function() { this_ref.close(); }
		this.el_container.appendChild(this.btn_close);

		this.btn_menu = document.createElement("button");
		this.btn_menu.classList.add("btn-menu");
		this.btn_menu.innerHTML = "<i class=\"mdi mdi-menu\"></i>"
		this.el_container.appendChild(this.btn_menu);

		this.el_container.appendChild(this.el_content);
		this.el_editor_container = app.createElement("div",["editor-container",content_type]);
		this.el_editor_container.this_ref = this;
		this.el_editor_container.appendChild(this.el_container);

		this.el_editor_container.addEventListener('focus',function(e){
			console.log("focused")
		});
		this.el_editor_container.addEventListener('blur',function(e){
			console.log("gone")
		});
		
		app.getElement("#sidewindow-container").appendChild(this.el_editor_container);
		instances.push(this);

		// update scroller
		let total_height = app.getElements("#sidewindow-container > .editor-container").length * app.getElement("#vscroll").clientHeight;
		app.getElement("#sidewindow-container > #vscroll > #fill").style.minHeight = total_height+"px";
	
		SideWindow.repositionWindows();
	}

	callResize () {
		let this_ref = this;
		blanke.cooldownFn('sidewin-resize-'+this.guid, 100, function(){	
			this_ref.onResize(this_ref.el_content.offsetWidth, this_ref.el_content.offsetHeight);
		});
	}

	get width () {
		return this.el_container.offsetWidth;
	}

	get height () {
		return this.el_container.offsetHeight;
	}

	focus () {
		return SideWindow.focus(this.title);
	}	

	// focus a fibwindow with a certain title if it exists
	static focus (title) {
		let child;
		for (let c in instances) {
			if (instances[c].title == title) {
				child = instances.splice(c,1)[0];
				instances.push(child);
			}
		}
		if (child) {
			SideWindow.repositionWindows();
			child.el_editor_container.scrollIntoView(true, {behavior:'smooth'});
			app.setHistoryMostRecent(child.history_id);
		}
		return child != null;
	}
	
	static repositionWindows () {
		let height = 0;
		for (let c in instances) {
			instances[c].el_editor_container.style.top = height+'px';
			height += instances[c].el_editor_container.clientHeight;
		}
	}
    
	setTitle (value) {
		if (this.el_title.innerHTML != value+this.subtitle) {
			this.el_title.innerHTML = value+this.subtitle;
			this.title = value;
			
			app.setHistoryText(this.history_id, this.title);
		}
	}

	setSubtitle (value) {
		this.subtitle = value || '';
		this.setTitle(this.title);
	}

	appendTo (element) {
		element.appendChild(this.el_container);
	}

	onResize (w, h) {

	}

	setContent (element) {
		this.el_content.innerHTML = "";
		this.el_content.appendChild(element);
	}

	appendChild (element) {
		this.el_content.appendChild(element);
	}

	appendBackground (element) {
		this.el_editor_container.appendChild(element);
	}

	close (remove_history) {
		instances = instances.filter((child) => child.title != this.title);
		SideWindow.repositionWindows();
		
		this.el_editor_container.remove();

		let total_height = app.getElements("#sidewindow-container > .editor-container").length * app.getElement("#vscroll").clientHeight;
		app.getElement("#sidewindow-container > #vscroll > #fill").style.minHeight = total_height+"px";
		
		if (this.onClose) remove_history = ifndef(this.onClose(), remove_history);

		if (remove_history)
			app.removeHistory(this.history_id);
		else
			app.setHistoryActive(this.history_id, false);
	}
    /*
	static closeAll (type) {
		var windows = app.getElements(".sidewin");
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
	}*/
}

document.addEventListener("ideReady",function(){
	let ignore_scroll = false;
	let el_sidewin_scroll = app.getElement("#sidewindow-container > #vscroll");
	let el_sidewin_container = app.getElement("#sidewindow-container");
	el_sidewin_container.addEventListener("scroll",function(e){
		if (ignore_scroll) {
			ignore_scroll = false
			return;
		}
		ignore_scroll = true;
		el_sidewin_scroll.scrollTop = (e.target.scrollTop / e.target.clientHeight) * el_sidewin_scroll.clientHeight;
	});
	el_sidewin_scroll.addEventListener("scroll",function(e){
		if (ignore_scroll) {
			ignore_scroll = false
			return;
		}
		ignore_scroll = true;
		el_sidewin_container.scrollTop = (e.target.scrollTop / e.target.clientHeight) * el_sidewin_container.clientHeight;
	});
});