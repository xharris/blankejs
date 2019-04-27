var count = 0;
var MAX_AGE = 6;

class Tab {
	constructor (content_type) {
		this.guid = guid()
		this.setTitle('tab'+count);
		count++;

		// add content to workspace
		var workspace = app.getElement('#workspace');
		this.tab_container = app.createElement('div', 'content');
		this.tab_container.dataset.type = content_type;
		this.tab_container.dataset.guid = this.guid;
		this.tab_container.this_ref = this;
		workspace.appendChild(this.tab_container);

		// add to history
		this.history_id = app.addHistory(this.title);
		Tab.focus(this.title);

		var this_ref = this;
		document.addEventListener('resize', function(e){
			this_ref.onResize(window.innerWidth, window.innerHeight);
		})
	}

	get width () {
		return this.tab_container.clientWidth;
	}

	get height () {
		return this.tab_container.clientHeight;
	}

	onResize (w, h) {
		console.log(w,h);
	}

	appendTo (element) {
		element.appendChild(this.tab_container);
	}

	appendChild (element) {
		this.tab_container.appendChild(element);
	}

	getContent () {
		return this.tab_container;
	}

	static hideAllTabs () {
		var contents = app.getElements("#workspace > .content");
		for (var t = 0; t < contents.length; t++) {
			contents[t].classList.add("hidden");
		}
	}

	static focus (title) {
		let found = false;
		let contents = app.getElements("#workspace > .content");
		for (var t = 0; t < contents.length; t++) {
			if (contents[t].this_ref.title == title){
				contents[t].classList.remove("hidden");
				found = true;
				app.addHistory(title);
			} else {
				contents[t].classList.add("hidden");
			}
		}
		return found;
	}

	setTitle (new_title) {
		this.title = new_title;
		app.setHistoryText(this.history_id, new_title);
	}

	setOnClick (fn, self) {
		var this_ref = this;
		var new_fn = function(self){
			if (!Tab.focus(this_ref.title)){
				fn(self);
			}
		}
		app.setHistoryClick(this.history_id, new_fn);
	}

	close () {
		if (this.onClose) this.onClose();
		
		app.setHistoryActive(this.history_id, false);
		app.removeHistory(this.history_id);
		this.tab_container.remove();
	}

	static closeAll (type) {
		var contents = app.getElements("#tabs > .tab");		
		for (var t = 0; t < contents.length; t++) {
			if (!type || (type && contents[t].dataset.type == type)) {
				contents[t].el_tab_container.remove();
				contents[t].remove();
			}
		}
	}

	static moveBack () {
		var contents = app.getElements("#tabs > .tab");
		var curr_title = app.getElement("#tabs > .tab:not(.hidden)").title;
		for (var t = 0; t < contents.length; t++) {
			if (contents[t].title == curr_title && t >= 1) {
				Tab.focus(contents[t-1].title);
				return;
			}
		}
	}
}

document.addEventListener('keydown', function(e){
	var keyCode = e.keyCode || e.which;

	if (e.altKey) {
		// move to left tab
		if (keyCode == 37) {
			Tab.moveBack();
		}
	}
});