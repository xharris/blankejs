var re_duplicate = /(.*)(\(\d+\)?)/;

class Console extends Editor {
	constructor (...args) {
		super(...args);

		this.setupDragbox();
		this.removeHistory()
		this.container.width = 460;
		this.container.height = 130;

		var this_ref = this;

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
		
		this.hideMenuButton();
	}

	processClosed () {
		if (!this.had_error)
			this.close();
	}

	log (str) {
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
		this.had_error = true;
		var re_error = /(\w+\.\w+:\d+):\s*(.+)/g;

		var error_parts = re_error.exec(str);
		if (error_parts) {
			str = "("+error_parts[1]+") "+error_parts[2]
		}

		var el_line = app.createElement("p", "error");
		el_line.innerHTML = str;
		this.el_log.appendChild(el_line);
		this.el_log.appendChild(app.createElement("br"));

		this.el_log.scrollTop = this.el_log.scrollHeight
	}
}
