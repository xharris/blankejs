class Console extends Editor {
	constructor (static_box, parent) {
		super();

		this.removeHistory();
		this.pin = false;

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
		this.appendChild(this.el_log);
	}

	appendTo (el) {
		el.appendChild(this.el_log);
		console.log(el, this.el_log)
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

	log (str) {
		let re_duplicate = /(.*)(\(\d+\)?)/g;

		str = JSON.stringify(str.trim()).slice(1,-1);
		let lines = str.split("\\n").map(line => JSON.parse("{\"str\":\""+line+"\"}").str)

		for (let line of lines) {
			if (line.match(re_duplicate) && this.el_log.childElementCount > 0) {
				this.el_log.lastElementChild.innerHTML = duplicate[0];
			} else {
				var el_line = app.createElement("p", "line");
				el_line.innerHTML = line;
				this.el_log.appendChild(el_line);
			}
		}

		this.el_log.scrollTop = this.el_log.scrollHeight;
	}

	err (str) {
		if (!this.had_error) {
			this.had_error = true;
			console.log(str);

			var el_line = app.createElement("p", "error");
			el_line.innerHTML = str;
			this.el_log.appendChild(el_line);
			this.el_log.appendChild(app.createElement("br"));

			this.el_log.scrollTop = this.el_log.scrollHeight
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