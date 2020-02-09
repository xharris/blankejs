let plugin_md_list = [];
let getDocPath = () => nwPATH.join(app.ideSetting("engine_path"),'docs');

class Docview extends Editor {
	constructor (...args) {
		super(...args);

		if (DragBox.focus('Docs')) return;

		this.setupDragbox();
		this.setTitle('Docs');
		this.removeHistory();
		this.hideMenuButton();

		this.container.width = 528;
		this.container.height = 272;

		var this_ref = this;

		this.doc_data = {};
		this.doc_container = app.createElement("div","doc-container");
		this.doc_body_container = app.createElement("div",["doc-body-container","markdown"]);
		this.appendChild(this.doc_container);
		this.appendChild(this.doc_body_container);

		let doc_path = getDocPath();
		nwFS.readFile(nwPATH.join(doc_path,'docs.json'), 'utf-8', (err, data) => {
			if (!err) {
				this.doc_sections = JSON.parse(data);
				this.doc_sections.Plugins = plugin_md_list;

				// put the divs together
				for (let category in this.doc_sections) {
					// CATEGORY
					let el_section = app.createElement("div","section");
					let el_header = app.createElement("p","header");
					let el_body = app.createElement("div",["body","hidden"]);

					let num_sections = Object.keys(this.doc_sections[category]).length;
					for (let subsection in this.doc_sections[category]) {
						let info = this.doc_sections[category][subsection];

						let el_subsection = app.createElement("div","subsection");
						let el_subheader = app.createElement("p","subheader");
						let el_subbody = this.doc_body_container;
						let el_doc = this.doc_container;

						let md_path = nwPATH.join(doc_path,info.file);
						el_subsection._tags = info.tags;
						el_subheader.innerHTML = info.title;
						
						let reveal = () => {
							// get .md content
							nwFS.readFile(md_path,'utf-8',(err,data) => {
								if (!err) {
									this.setSubtitle(" - "+(num_sections > 1 ? info.title : category));

									// el_subbody.innerHTML = markdown.toHTML(data);
									el_subbody.innerHTML = nwMD.render(data);

									if (el_subbody.innerHTML.trim() == "")
										el_subbody.innerHTML = "No information on this topic found";
									
									for (let c = 0; c < el_doc.children.length; c++) {
										el_doc.children[c].classList.remove('selected');
									}
									document.querySelectorAll('.subsection').forEach(sec => sec.classList.remove('selected'));

									if (num_sections > 1) {
										el_subsection.classList.add('selected');
									}
									if (num_sections == 1)
										el_section.classList.add('selected');

									// syntax highlighting
									document.querySelectorAll('code').forEach(block => {
										block.className = app.engine.language || '';
										hljs.highlightBlock(block);
									});
									// links
									document.querySelectorAll('a').forEach(block => {
										block.title = block.href;
									});
								}
							});	
						}

						if (num_sections == 1) {
							// ONLY 1 SUBSECTION
							el_section.classList.add('single');
							el_section.addEventListener('click', reveal);

						} else {
							// SUBSECTION
							el_subsection.appendChild(el_subheader);
							el_section.appendChild(el_subsection);
							el_subheader.addEventListener('click', reveal);
						}
					}

					el_header.innerHTML = category;
					el_header.title = category;

					el_section.prepend(el_header);

					this.doc_container.appendChild(el_section);
				}

				app.sanitizeURLs();
			}
		});
	}

	static addPlugin(title, file) {
		let found = false;
		file = nwPATH.relative(getDocPath(), file);

		plugin_md_list.forEach((obj) => {
			if (obj.title == title) {
				obj.file = file;
				found = true;
			} else if (obj.file == file) {
				obj.title = title;
				found = true;
			}
		});
		if (!found)
			plugin_md_list.push({"title":title, "file":file});
	}

	static removePlugin(file) {
		plugin_md_list = plugin_md_list.filter(p => p.file != file);
	}
}
