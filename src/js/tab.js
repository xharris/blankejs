var count = 0;
var MAX_AGE = 6;

class Tab {
	constructor (content_type) {
		this.guid = guid()
		this.title = 'tab'+count;
		count++;

		// add to tab bar
		var el_tab_bar = app.getElement("#tabs");
		this.tab = app.createElement("div","tab");
		this.tab.this_ref = this;
		this.tab.dataset.guid = this.guid;
		this.tab_title = app.createElement("div","tab-title");
		this.tab_tri_left = app.createElement("div", "triangle-left");
		this.tab_tri_right = app.createElement("div", "triangle-right");
		this.tab.appendChild(this.tab_title);
		this.tab.appendChild(this.tab_tri_left);
		this.tab.appendChild(this.tab_tri_right);
		el_tab_bar.appendChild(this.tab);

		// add content to workspace
		var workspace = app.getElement('#workspace');
		this.tab_container = app.createElement('div', 'content');
		this.tab_container.dataset.type = content_type;
		this.tab_container.dataset.guid = this.guid;
		workspace.appendChild(this.tab_container);

		this.tab.el_tab_container = this.tab_container;
		this.tab_container.el_tab = this.tab;

		this.setTitle(this.title);
		Tab.focusTab(this.title);

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

	static focusTab (title) {
		var contents = app.getElements("#tabs > .tab");
		var ret_val = false;
		var remove_elements = [];
		for (var t = 0; t < contents.length; t++) {
			if (contents[t].title == title) {
				contents[t].age = 0;

				contents[t].classList.remove("hidden");
				contents[t].el_tab_container.classList.remove("hidden");
				// move to front of tabs
				contents[t].parentNode.removeChild(contents[t]);
				app.getElement('#tabs').appendChild(contents[t]);
				ret_val = true;
			} else {

				contents[t].age += 1;

				if (contents[t].age > MAX_AGE) {
					remove_elements.push(contents[t].this_ref);
				}

				contents[t].classList.add("hidden");
				contents[t].el_tab_container.classList.add("hidden");
			}
		}

		return ret_val;
	}

	setTitle (new_title) {
		this.title = new_title;
		this.tab.title = new_title;
		this.tab_title.innerHTML = new_title;
	}

	setOnClick (fn, self) {
		var this_ref = this;
		var new_fn = function(self){
			if (!Tab.focusTab(this_ref.title)){
				fn(self);
			}
		}
		this.tab.addEventListener('click',new_fn);
		this.tab_title.addEventListener('click',new_fn);
	}

	close () {
		this.tab.remove();
		this.tab_container.remove();
	}

	static moveBack () {
		var contents = app.getElements("#tabs > .tab");
		var curr_title = app.getElement("#tabs > .tab:not(.hidden)").title;
		for (var t = 0; t < contents.length; t++) {
			if (contents[t].title == curr_title && t >= 1) {
				Tab.focusTab(contents[t-1].title);
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