class Docview extends Editor {
	constructor (...args) {
		super(...args);

		if (DragBox.focus('Docs')) return;

		this.setupDragbox();
		this.setTitle('Docs');
		this.removeHistory();
		this.hideMenuButton();

		this.container.width = 400;
		this.container.height = 350;

		var this_ref = this;

		this.doc_container = app.createElement("div","doc-container");

		let re = /--\[\[\s*#\s*[#\s]+(\w+)([^\]\[]+?)\]\]/g;
		let sections = [];
		nwFS.readFile(nwPATH.join(app.settings.engine_path,'lua','blanke','doc.lua'), 'utf-8', function(err, data){
			if (!err) {
				let matches = [];
				let doc_data = [];

				// get the headers
				do {
					matches = re.exec(data);
					if (matches) {
						sections.push([matches[1], matches[2], re.lastIndex - matches[0].length, re.lastIndex-1]);
					}
				} while (matches && matches.length);

				// get the content
				for (let s in sections) {
					let next_s = parseInt(s)+1
					if (sections[next_s]) {
						doc_data.push( [sections[s][0], sections[s][1], data.substring(sections[s][3]+1, sections[next_s][2])] );
					} else {
						doc_data.push( [sections[s][0], sections[s][1], data.substring(sections[s][3]+1)] );
					}
				}

				// put the divs together
				for (let sec of doc_data) {
					let el_section = app.createElement("div","section");
					let el_header = app.createElement("p","header");
					let el_body = app.createElement("div",["body","hidden"]);

					el_header.innerHTML = sec[0];
					el_header.title = sec[1].trim();
					el_body.innerHTML = sec[2];

					el_header.addEventListener('click',function(){
						el_body.classList.toggle('hidden');
					});

					el_section.appendChild(el_header);
					el_section.appendChild(el_body);

					this_ref.doc_container.appendChild(el_section);
				}

				this_ref.appendChild(this_ref.doc_container);
			}
		});
	}
}