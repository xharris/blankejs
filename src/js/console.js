class Console extends Editor {
	constructor (windowed) {
		super();
		if (windowed) {
			this.setupDragbox();
			this.width = 400;
			this.height = 160;
		}

		this.removeHistory();
		this.pin = false;
		this.duplicate_count = 1;

		this.el_log = app.createElement("div", "log");
		this.el_lines = app.createElement("div", "lines");
		this.last_line = '';
		this.str_console = '';
		this.last_dupe_line = '';
		this.auto_scrolling = true;

		// auto-scroll toggle
		this.el_autoscroll = app.createIconButton("scroll","toggle auto-scroll");
		this.el_autoscroll.addEventListener('click',()=>{
			this.auto_scrolling = !this.auto_scrolling;
		})
		//this.el_log.appendChild(this.el_autoscroll);
		this.el_log.appendChild(this.el_lines);

		this.appendChild(this.el_log);
	}

	tryClose () {
		if (!this.had_error && !this.pin)
			this.close();
	}

	appendTo (el) {
		el.appendChild(this.el_log);
	}

	onMenuClick (e) {
		var this_ref = this;
		app.contextMenu(e.x, e.y, [{
			label:'pin',
			checked: this_ref.pin,
			click:function(){ this_ref.pin = !this_ref.pin; }
		}]);
	}

	toggleVisibility () {
		this.el_log.classList.toggle('hidden');
	}

	isVisible () {
		return !this.el_log.classList.contains('hidden');
	}

	processClosed () {
		if (!this.had_error && !this.pin)
			this.close();
	}

	clear () {
		this.el_lines.innerHTML = '';
		blanke.removeChildClass(this.el_log, 'error');
		// blanke.removeChildClass(this.el_log, 'separator');
		this.str_console = '';
		this.last_line = '';
		this.last_dupe_line = '';
		this.duplicate_count = 1;
		this.had_error = false;
	}

	clearError () {

	}

	parse (line) {
		// one-liner limits object depth
		return line.map(l => typeof l == 'object' ? nwUTIL.inspect(l, { compact: true }) : l);
	}

	log (...args) {
		// parse args
		let str = this.parse(args); 
		// TODO: add string length limiter
		if (this.last_line == str) {
			this.duplicate_count++;
			if (this.last_dupe_line !== '')
				this.str_console = this.str_console.slice(0, -this.last_dupe_line.length);	
			else 
				this.str_console = this.str_console.slice(0, -(this.last_line+'\n').length);
			this.last_dupe_line = `${str} (${this.duplicate_count})\n`;
			this.str_console += this.last_dupe_line; 
		} else {
			this.duplicate_count = 1;
			this.last_dupe_line = '';
			this.str_console += `${str}`+(engine.console_new_line ? '\n' : '');
		}
		this.last_line = str;
		if (this.isVisible()) this.el_lines.innerHTML = this.str_console;

		if (this.auto_scrolling) {
			blanke.cooldownFn("console.log", 100, ()=>{	
				this.el_log.scrollTop = this.el_log.scrollHeight;
			});
		}
	}

	err (str) {
		if (!this.had_error) {
			this.had_error = true;

			var el_line = app.createElement("p", "error");
			el_line.innerHTML = str;
			this.el_log.appendChild(el_line);
			// this.el_log.appendChild(app.createElement("br","separator"));

			el_line.scrollIntoView({ behavior: 'auto' , block: 'nearest', inline: 'nearest'});
		}
	}
}

document.addEventListener("openProject", function(e){
	app.removeSearchGroup("Debug");
	app.addSearchKey({key: 'Re-run', group: 'Debug', onSelect: function() {
		app.play('--play-record');
	}});
	app.addSearchKey({key: 'Run', group: 'Debug', onSelect: function() {
		app.play();
	}});


	// shortcut: run game
	app.newShortcut({
		key: "CommandOrControl+B", active: function() {
			app.play();
		}
	});

	// shortcut: run recording
	app.newShortcut({
		key: "CommandOrControl+Shift+B", active: function() {
			app.play('--play-record');
		}
	});
});