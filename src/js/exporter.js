class Exporter extends Editor {
	constructor (...args) {
		super(...args);

		if (DragBox.focus('Exporter')) return;

		this.setupDragbox();
		this.setTitle('Exporter');
		this.hideMenuButton();

		this.container.width = 400;
		this.container.height = 350;

		var this_ref = this;

		this.platforms = ['windows','mac','linux'];

		this.el_platforms = app.createElement("div","platforms");
		let el_title1 = app.createElement("p","title1");
		el_title1.innerHTML = "One-click export";
		this.el_platforms.appendChild(el_title1);
		
		for (let p of this.platforms) {
			let el_platform_container = app.createElement("button",["ui-button-rect","platform",p]);
			let el_platform_icon = app.createElement("img","icon");
			el_platform_icon.src = "icons/windows.png";

			el_platform_container.appendChild(el_platform_icon);
			this.el_platforms.appendChild(el_platform_container);
		}

		this.appendChild(this.el_platforms);
	}
}

document.addEventListener("openProject", function(e){
	app.removeSearchGroup("exporter");
	app.addSearchKey({key: 'Export game', onSelect: function() {
		new Exporter(app);
	}});
});