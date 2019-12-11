let plugin_md_list = [];
let getDocPath = () => nwPATH.join(app.ideSetting("engine_path"),'docs');

class Docview extends Editor {
	constructor (...args) {
		super(...args);

		if (DragBox.focus('Docs', true)) return;

		this.setupDragbox();
		this.setTitle('Docs');
		this.removeHistory();
		this.hideMenuButton();

		this.container.width = 400;
		this.container.height = 448;

		var this_ref = this;

		this.doc_data = {};
		this.doc_container = app.createElement("div","doc-container");

		let doc_path = getDocPath();
		nwFS.readFile(nwPATH.join(doc_path,'docs.json'), 'utf-8', function(err, data){
			if (!err) {
				this_ref.doc_sections = JSON.parse(data);
				this_ref.doc_sections.Plugins = plugin_md_list;

				// put the divs together
				for (let category in this_ref.doc_sections) {
					// CATEGORY
					let el_section = app.createElement("div","section");
					let el_header = app.createElement("p","header");
					let el_body = app.createElement("div",["body","hidden"]);

					let num_sections = Object.keys(this_ref.doc_sections[category]).length;
					for (let subsection in this_ref.doc_sections[category]) {
						let info = this_ref.doc_sections[category][subsection];

						let el_subsection = app.createElement("div","subsection");
						let el_subheader = app.createElement("p","subheader");
						let el_subbody = app.createElement("div",["subbody","hidden","markdown"]);

						let md_path = nwPATH.join(doc_path,info.file);
						el_subsection._tags = info.tags;
						el_subheader.innerHTML = info.title;
						
						el_subbody.reveal = () => {
							// get .md content
							nwFS.readFile(md_path,'utf-8',function(err,data){
								if (!err) {

									// el_subbody.innerHTML = markdown.toHTML(data);
									el_subbody.innerHTML = nwMD.render(data);

									if (el_subbody.innerHTML.trim() == "")
										el_subbody.innerHTML = "No information on this topic found";
									el_subbody.classList.toggle('hidden');
									el_subsection.classList.toggle('expanded');

									// syntax highlighting
									document.querySelectorAll('code').forEach(block => {
										block.className = engine.language || '';
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
							el_body.appendChild(el_subbody);
							el_body.classList.add("single");
							el_header.addEventListener('click',el_subbody.reveal);

						} else {
							// SUBSECTION
							el_subsection.appendChild(el_subheader);
							el_subsection.appendChild(el_subbody);

							el_body.appendChild(el_subsection);

							el_subheader.addEventListener('click',el_subbody.reveal);
						}
					}

					el_header.innerHTML = category;
					el_header.title = category;

					el_section.appendChild(el_header);
					el_section.appendChild(el_body);
					
					el_header.addEventListener('click',function(){
						el_body.classList.toggle('hidden');
					});

					this_ref.doc_container.appendChild(el_section);
				}

				this_ref.appendChild(this_ref.doc_container);
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
