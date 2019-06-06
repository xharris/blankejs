var instances = [];
var curr_category = '';
var MAX_WINDOWS = 10; //5;
var curr_focus;

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
			
		});
		this.el_editor_container.addEventListener('blur',function(e){
			
		});
		
		app.getElement("#sidewindow-container").appendChild(this.el_editor_container);
		instances.push(this);
	
		SideWindow.repositionWindows();
		this.setTitle("new sidewindow");
		this.focus();
	}

	getContent () {
		return this.el_editor_container;
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

	_onEnterView () {
		if (!this.focused) {
			this.focused = true;
			app.getElements('.sidewin').forEach(function(e){
				e.classList.remove('focused');
			});
			this.el_container.classList.add('focused');
			if (this.onEnterView) this.onEnterView();
		}
	}
	_onExitView () {
		if (this.focused) {
			this.focused = false;
			if (this.onExitView) this.onExitView();
		}
	}

	// focus a fibwindow with a certain title if it exists
	static focus (title) {
		let child;
		for (let c in instances) {
			if (instances[c].title == title) {
				child = instances[c];
				child._onEnterView();
			} else {
				instances[c]._onExitView();
			}

			if (child && c < instances.length-1) {
				child = instances.splice(c,1)[0];
				instances.push(child);
				SideWindow.repositionWindows();
				app.setHistoryMostRecent(child.history_id);
			}
		}
		if (child) {
			SideWindow.focusing = child;
			if (curr_focus && curr_focus.title == child.title) {
				child.el_editor_container.scrollIntoView({ behavior: 'auto' , block: 'start', inline: 'nearest'});
				checkScrolling(true);
			} else {
				child.el_editor_container.scrollIntoView({ behavior: 'smooth' , block: 'start', inline: 'nearest'});
				checkScrolling();
			}
			app.setHistoryHighlight(child.history_id);
		}
		return child != null;
	}
	
	static repositionWindows () {
		let height = 0;
		for (let c in instances) {
			instances[c].el_editor_container.style.top = height+'px';
			height += instances[c].el_editor_container.clientHeight;
		}
		SideWindow.updateScroll();
	}

	static updateScroll () {
		// update scroller
		let container = app.getElement("#sidewindow-container > #vscroll");
		blanke.clearElement(container);
		for (let d = 0; d < instances.length; d++) {
			let new_fill = app.createElement("div",".fill");
			new_fill.style.minHeight = container.clientHeight+"px";
			container.appendChild(new_fill);
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
		console.log(w,h);

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
		SideWindow.updateScroll();
		
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

let checkScrolling = (check_focus) => {
	let el_sidewin_container = app.getElement("#sidewindow-container");
	let el_sidewin_scroll = app.getElement("#sidewindow-container > #vscroll");
	let scroll_y = el_sidewin_container.scrollTop;
	
	for (let win of instances) {
		let win_y = parseInt(win.el_editor_container.style.top);
		let win_h = win.el_editor_container.clientHeight;
		let win_bottom = win_y + win_h;
		if (scroll_y + (win_h/2) >= win_y && 
			scroll_y + (win_h/2) < win_bottom) {
				app.setHistoryHighlight(win.history_id);
				curr_focus = win;
				win._onEnterView();
			}
		else
			win._onExitView();
		
		
		if (check_focus) {
			// don't track scrolling if scrollIntoView was used in .focus()
			if (scroll_y >= win_y &&
				scroll_y < win_bottom &&
				SideWindow.focusing && SideWindow.focusing.title == win.title) {
					SideWindow.focusing = false;
					el_sidewin_scroll.scrollTop = (scroll_y / el_sidewin_container.clientHeight) * el_sidewin_scroll.clientHeight;
				}
		}
	}
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
		let scroll_y = el_sidewin_container.scrollTop;
		if (!SideWindow.focusing)
			el_sidewin_scroll.scrollTop = (scroll_y / el_sidewin_container.clientHeight) * el_sidewin_scroll.clientHeight;

		// update history with currently viewed window
		checkScrolling(true);
	});
	el_sidewin_scroll.addEventListener("scroll",function(e){
		if (ignore_scroll) {
			ignore_scroll = false
			return;
		}
		ignore_scroll = true;
		let scroll_y = el_sidewin_scroll.scrollTop;
		if (!SideWindow.focusing)
			el_sidewin_container.scrollTop = (scroll_y / el_sidewin_scroll.clientHeight) * el_sidewin_container.clientHeight;
		
		// update history with currently viewed window
		checkScrolling();
	});
});

window.addEventListener('resize',() => SideWindow.updateScroll());