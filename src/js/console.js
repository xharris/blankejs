class Console extends Editor {
	constructor (static_box, parent) {
		super();

		this.removeHistory();
		this.pin = false;
		this.duplicate_count = 1;

		/*
		this.process = [...args][0];
		if (this.process) {
			this.process.stdout.on('data', function(data){
				data = data.toString();

				if (!data.includes("attempt to call global") && !data.includes("attempt to call a string value")) {
					if (data.includes("error") || data.includes("Error"))  {
						this_ref.err(data);
					} else {
						this_ref.log(data);
					}
				}
			});
		}
		*/

		this.el_log = app.createElement("div", "log");
		this.el_lines = app.createElement("div", "lines");
		this.last_line = '';
		this.str_console = '';
		this.last_dupe_line = '';

		this.el_log.appendChild(this.el_lines)
		this.appendChild(this.el_log);
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

	processClosed () {
		if (!this.had_error && !this.pin)
			this.close();
	}

	clear () {
		this.el_lines.innerHTML = '';
		var el_err = document.getElementsByClassName('hi');
		blanke.removeChildClass(this.el_log, 'error');
		this.str_console = '';
		this.last_line = '';
		this.last_dupe_line = '';
		this.duplicate_count = 1;
		this.had_error = false;
	}

	log (str) {
		str = JSON.stringify(str.trim()).slice(1,-1);
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
			this.str_console += `${str}\n`;
		}
		this.last_line = str;
		blanke.cooldownFn("console.log", 100, ()=>{	
			this.el_lines.innerHTML = this.str_console;
			this.el_log.scrollTop = this.el_log.scrollHeight;
		});
	}

	err (str) {
		if (!this.had_error) {
			this.had_error = true;

			var el_line = app.createElement("p", "error");
			el_line.innerHTML = str;
			this.el_log.appendChild(el_line);
			this.el_log.appendChild(app.createElement("br"));

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
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Ctrl+B", active: function() {
			app.play();
		}
	}));
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Command+B", active: function() {
			app.play();
		}
	}));

	// shortcut: run recording
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Ctrl+Shift+B", active: function() {
			app.play('--play-record');
		}
	}));
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Command+Shift+B", active: function() {
			app.play('--play-record');
		}
	}));
});