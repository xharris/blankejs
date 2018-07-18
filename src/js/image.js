var nwRECURSIVE = require("recursive-readdir");

class ImageBrowser extends Editor {
	constructor (...args) {
		super(...args);
		this.setupTab();
		this.setTitle('Image Browser');

		// setup UI
		this.el_image_list = app.createElement("div","image-list");
		//this.el_image_

		// scan images in project dir
		let this_ref = this;
		function ignoreFiles (file, stats) {
			return (
				stats.isFile() &&
				!["png","jpg","jpeg","gif","psd","tiff","tga","bmp"].includes(nwPATH.extname(file).slice(1))
			);
		}
		nwRECURSIVE(this.app.project_path, [ignoreFiles],
		function(err, files){
			for (img_path of files) {
				this_ref.addImage(img_path);
			}
		});

		this.images = {}
	}

	addImage (img_path) {

	}
}

document.addEventListener("openProject", function(e){
	app.addSearchKey({
		key: 'View images',
		onSelect: function() {
			if (!Tab.focus('Image Browser'))
				new ImageBrowser(app);
		},
		tags: ['view']
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