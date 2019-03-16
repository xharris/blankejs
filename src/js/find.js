class Find extends Editor {
	constructor (...args) {
		super(...args);
		var this_ref = this;

		this.setupDragbox();
		this.removeHistory();
		this.container.width = 400;
		this.container.height = 250;

		this.el_search_form = new BlankeForm([
			['search','text',{'label':false}],
			['submit','button',{'label':'search'}]
		]);
		this.el_search_form.onChange('submit',function(){
			this_ref.search(this_ref.el_search_form.getValue("search"));
		});
		this.el_search_form.onEnter('search',function(e){
			e.preventDefault();
			this_ref.el_search_form.getInput('submit').click();
		});

		this.el_result_container = app.createElement("div","result-container");

		this.appendChild(this.el_search_form.container);
		this.appendChild(this.el_result_container);

		this.el_search_form.getInput('search').focus();

		this.hideMenuButton();
		this.setTitle("Find in files");
	}

	search (query) {
		let this_ref = this;

		app.getAssets('script', function(files){
			let re_query = new RegExp(query);
			this_ref.el_result_container.innerHTML = `<p class='no-result'>No results for "${query}"</p>`;

			let first = true;
			for (let f of files) {
				// check if file contains query
				nwFS.readFile(f,'utf-8',function(err, data){
					if (!err && re_query.test(data)) {
						if (first) {
							first = false;
							this_ref.el_result_container.innerHTML = '';
						}
						this_ref.parseResult(f,data,re_query);
					}
				});
			}
		});
	}

	parseResult (filename, text, regex) {
		let lines = text.split('\n');
		let str_body = '';
		let count = 0;
		let result_margin = 1;

		for (let l = 0; l < lines.length; l++) {
			if (regex.test(lines[l])) {
				count++;

				// add surrounding lines to html
				str_body += `<div class='result'><button class='btn-open-file' onclick='Code.openScript(decodeURI("${encodeURI(filename)}"), ${l})'><i class='mdi mdi-arrow-top-right-thick'></i></button>`;
				let end_l = l;

				for (let s = l-result_margin; s < end_l+1; s++) {
					if (s >= 0 && s < lines.length) {
						// using elseif is similar to xor
						if (regex.test(lines[s]) || (s+result_margin < lines.length && regex.test(lines[s+result_margin])))
							end_l = s+result_margin;

						str_body += 
							"<div class='line'>"+
								"<p class='number'>"+(s+1)+"</p>"+
								"<pre class='text'>"+lines[s].replace(regex,"<i class='match'>$&</i>")+"</pre>"+
							"</div>";
					}
				}
				l = end_l+1;
				str_body += "</div>";
			}
		}
		let str_html = "<div class='result-group collapsed'><div class='resize'></div><p class='filename'>"+nwPATH.basename(filename)+" ("+count+")</p>"+str_body+"</div>";

		if (count > 0) {
			this.el_result_container.innerHTML += str_html;
			// event: collapse file results on title click
			Array.from(app.getElements('.result-group > .resize')).forEach(function(element) {
		    	element.addEventListener('click', function(e){
		    		e.target.parentNode.classList.toggle("collapsed");
		    	});
		    });
		}
	}
}

document.addEventListener("closeProject", function(e){	
	app.removeSearchGroup("Find");
});

document.addEventListener("openProject", function(e){
	app.addSearchKey({
		key: 'Find in files',
		onSelect: function() {
			new Find(app);
		},
		group: 'Find'
	});
});