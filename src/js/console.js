class Console extends Editor {
	constructor (...args) {
		super(...args);

		this.setupDragbox();
		this.removeHistory()
		this.container.width = 460;
		this.container.height = 130;

		var this_ref = this;

		this.pin = false;

		this.process = [...args][1];
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

		this.el_log = app.createElement("div", "log");
		this.appendChild(this.el_log);
		this.el_log.focus();
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

			let re_error = /Error:\s.*[^\\\/Blanke\.lua]?[\w\\\/\.]+\/(\w+\.lua):(\d+):\s(.+)\s*stack traceback:\s+(.*)/g;
			let re_load_error = /:\s(.*):(\d+):\s(.*)/g
			let re_shader_error = /.*pixel shader code:\s*([\s\S]*)stack/g
			let re_shader_message = /(?:Line\s(\d+):\sERROR:\s*(.*)\s*(?=Line|ERROR))/g

			let error_parts;

			// pixel shader error
			if (str.includes("pixel shader code")) {
				let match,
				message = '',
				header = 'Shader error<br>';

				while (match = re_shader_message.exec(str)) {
					if (!match[2].includes('terminated'))
						message += "Line "+(match[1]-22)+": "+match[2]+"<br>";
				}

				str = header+message;
			}

			// regular error
			else if (error_parts = re_error.exec(str)) {
				let filename = nwPATH.basename(error_parts[1])
				let line = error_parts[2]
				let message = error_parts[3]
				let traceback = error_parts[4]

				if (filename.includes('Blanke.lua')) {
					// error after game is loaded
					let message_parts = re_load_error.exec(message)

					if (message_parts) {
						filename = message_parts[1]
						line = message_parts[2]
						message = message_parts[3]
					}
				}
				// error during runtime
				str = filename+" ("+line+"): "+message	
			}

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