var re_duplicate = /(.*)(\(\d+\)?)/;
var consoles_active = 0;

class Console extends Editor {
	constructor (...args) {
		super(...args);

		if (consoles_active == 0) {
			Editor.closeAll('Console');
		}

		this.setupDragbox();
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
		
		consoles_active += 1;

		this.close_called = false;
		this.addCallback('onClose', this.processClosed);

		this.hideMenuButton();
	}

	processClosed () {
		if (!this.close_called) {
			this.close_called = true;
			consoles_active -= 1;
		}
	}

	log (str) {
		str = str.trim();
		var duplicate = re_duplicate.exec(str);
		
		if (str !== ')' && str !== '') {
			if (duplicate !== null) {
				this.el_log.lastElementChild.innerHTML = duplicate[0];
			} else {
				var el_line = app.createElement("p", "line");
				el_line.innerHTML = str;
				this.el_log.appendChild(el_line);
			}
		}

		this.el_log.scrollTop = this.el_log.scrollHeight;
	}

	err (str) {
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
