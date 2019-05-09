class SpritesheetPreview extends Editor {
	constructor (img_name) {
		super();
		// TODO: add option to give default values for el_sheet_form
		let this_ref = this;

		this.setupDragbox();
		this.removeHistory();
		this.hideMenuButton();
		this.container.width = 550;
		this.container.height = 370;

		this.scale = 1;

		this.setTitle('Spritesheet Preview');

		// setup form
		this.selected_img = null;
		this.el_sheet_form = new BlankeForm([
			['name', 'text'],
			['offset', 'number', {'inputs':2, 'separator':'x'}],
			['speed', 'number', {'inputs':1,'step':'0.1','min':'0','default':"1.0"}],
			['frame size', 'number', {'inputs':2, 'separator':'x'}],
			['frames','number',{'inputs':1}],
			['columns','number',{'inputs':1}],
			['border','number',{'inputs':1}]
		]);
		this.el_sheet_form.onChange('speed',function(val){
			if (val < 0) return 1;
		});
		this.el_sheet_form.container.classList.add("dark");
		this.appendChild(this.el_sheet_form.container);

		// add animation preview elements
		this.el_prvw_container = blanke.createElement("div", ["prvw-container", "no-custom-scroll"]);
		this.el_image = blanke.createElement("img", "image");
		this.el_image_container = blanke.createElement("div", "img-container");
		this.el_preview = blanke.createElement("canvas", "prvw");
		this.el_btn_show_prvw = blanke.createElement("button", "show-prvw");
		this.el_frames_container = blanke.createElement("div", "frames-container");
	  	this.el_image_size = app.createElement("span","image-size");

		this.el_image.draggable = false;
		this.el_btn_show_prvw.innerHTML = "PREVIEW";
		this.el_btn_show_prvw.addEventListener("mouseenter",function(){
			this_ref.el_prvw_container.classList.add('enable-prvw');
		});
		this.el_btn_show_prvw.addEventListener("mouseleave",function(){
			this_ref.el_prvw_container.classList.remove('enable-prvw');
		});

		this.el_zoom_container = blanke.createElement("div","zoom-container");
		this.el_zoom_in = blanke.createElement("button","zoom-in");
		this.el_zoom_in.innerHTML = "+";
		this.el_zoom_out = blanke.createElement("button","zoom-out");
		this.el_zoom_out.innerHTML = "-";
		this.el_zoom_amt = blanke.createElement("p","zoom-amt");
		this.el_zoom_amt.innerHTML = "100";
		this.el_zoom_in.addEventListener('click',function(e){
			this_ref.setScale(this_ref.scale+0.1);
		});
		this.el_zoom_out.addEventListener('click',function(e){
			this_ref.setScale(this_ref.scale-0.1);
		});
		this.el_zoom_container.appendChild(this.el_zoom_in);
		this.el_zoom_container.appendChild(this.el_zoom_out);
		this.el_zoom_container.appendChild(this.el_zoom_amt);

		this.el_image_container.appendChild(this.el_image);
		this.el_image_container.appendChild(this.el_frames_container);

		this.el_prvw_container.appendChild(this.el_image_container);
		this.el_prvw_container.appendChild(this.el_preview);
		this.appendChild(this.el_zoom_container);
		this.appendChild(this.el_image_size);
		this.appendChild(this.el_btn_show_prvw);
		this.appendChild(this.el_prvw_container);

		// start animation
		this.frames = [];
		this.frame_coords = [];
		this.frame = 0;
		this.duration = this_ref.el_sheet_form.getValue("speed")*1000;
		this.ctx = this.el_preview.getContext("2d");
		this.then = Date.now();
		
		this._showNextFrame();

		// scan images in project dir
		this.image_list = [];
		app.getAssets("image", function(...args){ 
			this_ref.addImage(...args);

			// set default image if given
			if (img_name && img_name != '') {
				let match;
				for (let i = 0; i < this_ref.image_list.length; i++) {
					console.log(this_ref.image_list[i])
					if (match = this_ref.image_list[i].match(/image[\\/]+([/\\-\s\w]*)\./)) {
						if (match[1] == img_name) {
							this_ref.setImage(this_ref.image_list[i]);
						}
					}
				}
			}
		});

		document.addEventListener("asset_added",function(){
			app.getAssets("image", function(...args){ this_ref.addImage(...args); });
		});
	}

	setScale(new_scale) {
		this.scale = new_scale
		
		let element_names = ['el_image','el_frames_container','el_preview'];
		for (let name of element_names) {
			if (app.os == "win")
				this[name].style.transform = "scale3d("+this.scale+","+this.scale+","+this.scale+")";
			else
				this[name].style.transform = "scale("+this.scale+")";
		}
		this.el_zoom_amt.innerHTML = parseInt(this.scale*100);
	}

	_onCopyCode () {
		this.getValues()
		if (this.onCopyCode) {
			blanke.toast("Animation code copied! Don't forget to save.");
			this.onCopyCode(this.getValues());
		} else {
			blanke.toast("Can't copy any code right now.");
		}
	}

	addImage (img_list) {
		let this_ref = this;

		for (let i in img_list)
			img_list[i] = app.shortenAsset(img_list[i]);
		this.image_list = img_list;

		// image select
		this.el_sheet_form.removeInput("image");
		this.el_sheet_form.addInput(['image','select',{
			'placeholder':'...','default':this.selected_img,'choices':img_list
		}]);
		// copy code button
		this.el_sheet_form.removeInput("copy code");
		this.el_sheet_form.addInput(['copy code', 'button']);
		this.el_sheet_form.onChange("copy code",function(){
			this_ref._onCopyCode();
		});

		// on image change event
		this.el_sheet_form.onChange("image",function(val){
			this_ref.setImage(val);
		});
		for (let prop of ["name","offset","speed","border", "frame size", "frames", "columns"]) {
			this.el_sheet_form.onChange(prop, function(){ this_ref.updateFrames(); });
		}

		this.updateFrames();
	}

	setImage (name) {
		let this_ref = this;

		this.el_sheet_form.setValue("image", name);

		this.selected_img = app.cleanPath(name);
		let src = "file://"+decodeURI(app.lengthenAsset(this.selected_img))
		
		this.el_image.onload = function(){
			this_ref.el_preview.innerHTML = "<img src='"+src+"'/>";
			let img_w = this_ref.el_image.width, img_h = this_ref.el_image.height;
			this_ref.el_preview.width = img_w;
			this_ref.el_preview.height = img_h;

			this_ref.el_image_size.innerHTML = img_w + " x " + img_h;

			// use last used values
			if (app.project_settings.spritesheet_prvw && app.project_settings.spritesheet_prvw[app.cleanPath(this_ref.selected_img)]) {
				this_ref.el_sheet_form.useValues(app.project_settings.spritesheet_prvw[app.cleanPath(this_ref.selected_img)]);
			}

			// fit image into window frame
			let container_w = this_ref.el_image_container.offsetWidth, container_h = this_ref.el_image_container.offsetHeight;
			let calculated_scale = container_w / img_w > container_h / img_h ? container_w / img_w : container_h / img_h;
			this_ref.setScale(calculated_scale > 1.0 ? calculated_scale / 2.0 : calculated_scale);

			this_ref.updateFrames();
		}

		this.el_image.src = src;
	}

	getValues () {
		let name = this.el_sheet_form.getValue("name");
		let offset = [this.el_sheet_form.getValue("offset",0), this.el_sheet_form.getValue("offset",1)];
		let speed = this.el_sheet_form.getValue("speed");
		let frame_dims = [this.el_sheet_form.getValue("frame size",0), this.el_sheet_form.getValue("frame size",1)];
		let frames = this.el_sheet_form.getValue("frames");
		let columns = this.el_sheet_form.getValue("columns");
		let border = this.el_sheet_form.getValue("border");
		return {
			'name':name,'offset':offset,'speed':speed,'frame size':frame_dims,
			'frames':frames,'selected frames':this.frames,'columns':columns,'border':border,'image':this.selected_img
		}
	}

	updateFrames () {
		let this_ref = this;
		let vals = this.getValues();

		// save last used values for this image
		if (!app.project_settings.spritesheet_prvw)
			app.project_settings.spritesheet_prvw = {};
		if (this.selected_img) 
			app.project_settings.spritesheet_prvw[app.cleanPath(this.selected_img)]=vals
		app.saveSettings();

		// create the rectangles
		blanke.clearElement(this.el_frames_container);
		let x = vals.offset[0] + vals.border, y = vals.offset[1] + vals.border;
		for (let f = 0; f < vals.frames; f++) {
			let el_frame = blanke.createElement("div","frame");
			el_frame.style.left = x+'px';
			el_frame.style.top = y+'px';
			el_frame.style.width = vals['frame size'][0]+'px';
			el_frame.style.height = vals['frame size'][1]+'px';
			el_frame.draggable = false;
			el_frame.addEventListener("click",function(){
				el_frame.classList.toggle("ignore");
				this_ref.updateAnimation();
			});
			this.el_frames_container.appendChild(el_frame);

			x += vals['frame size'][0] + vals.border;
			
			if ( x > vals.offset[0] + ((vals.columns-1) * (vals['frame size'][0]+(vals.columns*vals.border) )) ) {
				x = vals.offset[0] + vals.border;
				y += (vals['frame size'][1] + vals.border);
			}
		}

		this.updateAnimation();
	}

	updateAnimation () {
		let this_ref = this;

		// update animation preview
		let frame_coords = [];
		let el_frames = Array.from(this.el_frames_container.children);
		let img_width = this.el_image.width;
		let img_height = this.el_image.height;
		let vals = this.getValues();

		this.frames = [];
		this.frame_coords = [];
		let last_chain_couple, last_x, last_y, new_x, new_y, last_ignored = false, x_chain = [1,1], y_chain = [1,1], curr_chain;

		function getChainCouple() {
			let xc, yc;
			// turn x and y into a single string/int
			if (x_chain[0] == x_chain[1]) xc = x_chain[0];
			else xc = '\"'+x_chain[0]+"-"+x_chain[1]+"\"";
			if (y_chain[0] == y_chain[1]) yc = y_chain[0];
			else yc = '\"'+y_chain[0]+"-"+y_chain[1]+"\"";
			return [xc, yc];
		}

		function addChain(chain) {
			// add it to list of frames
			this_ref.frames.push(chain[0], chain[1]);
		}

		for (let f = 0; f < el_frames.length; f++) {
			let ignore_frame = false; // TODO: not implemented yet
			
			let x = parseInt(el_frames[f].style.left);
			let y = parseInt(el_frames[f].style.top);
			this.frame_coords.push([
				x, y,
				parseInt(el_frames[f].style.width), parseInt(el_frames[f].style.height)
			]);

			new_x = Math.floor((x-vals.offset[0]) / (vals['frame size'][0] + vals.border)) + 1;
			new_y = Math.floor((y-vals.offset[1]) / (vals['frame size'][1] + vals.border)) + 1;
			// moving to a new row
			if (new_y > last_y) {
				curr_chain = getChainCouple();
				y_chain[1] = new_y;
				if (!last_chain_couple) {
					// this is the 2nd row
					x_chain = [1,1];
				} else {
					// the number of columns for this row was different than the last
					if (curr_chain[0] != last_chain_couple[0]) {
						addChain(last_chain_couple);
						y_chain = [new_y, new_y];
					}
				}
				last_chain_couple = [curr_chain[0], curr_chain[1]];
			}
			if (new_x != last_x) x_chain[1] = new_x;
			
			if (!ignore_frame) {
				last_x = new_x; last_y = new_y;
				last_ignored = false;
			} else {
				last_ignored = true;
			}
		}
		curr_chain = getChainCouple();
		// if the number of columns never changed, then addChain does not get called in the for loop
		if (this.frames.length == 0)
			if (last_chain_couple) addChain(last_chain_couple);
			else addChain(curr_chain);
		// if the number of columns changed in the last row, add that row
		if (last_chain_couple && last_chain_couple[0] != curr_chain[0] && last_chain_couple[1] != curr_chain[1]) addChain(curr_chain);

		this.duration = this_ref.el_sheet_form.getValue("speed")*1000;
	}

	_showNextFrame () {
		let this_ref = this;
		let ctx = this.ctx, frame_coords = this.frame_coords, frame = this.frame; 
		let duration = this.duration;

		if (!this.then) this.then = Date.now();

		let now = Date.now();
		let delta = now - this.then;
		if (delta < duration) {window.requestAnimationFrame(this._showNextFrame.bind(this));return;}
		this.then = now - (delta%duration);

		if (frame_coords[frame]) {
			ctx.clearRect(0,0,this.el_preview.width,this.el_preview.height);
			ctx.drawImage(this.el_image,
				frame_coords[frame][0], frame_coords[frame][1], frame_coords[frame][2], frame_coords[frame][3],
				0, 0, frame_coords[frame][2], frame_coords[frame][3]); 
		}
		this.frame += 1;
		if (frame >= frame_coords.length - 1) this.frame = 0;

		window.requestAnimationFrame(this._showNextFrame.bind(this));
	}
}

document.addEventListener("openProject", function(e){
	app.addSearchKey({
		key: 'Preview a spritesheet',
		onSelect: function() {
			new SpritesheetPreview();
		},
		tags: ['view'],
		category: 'tools'
	});
	app.addSearchKey({
		key: 'Add images',
		onSelect: function() {
			blanke.chooseFile('file', function(files){
				files = files.split(';');
				for (var f of files) {
					app.addAsset('image',f);
				}
			}, true, true);
		},
		tags: ['view']
	});
});