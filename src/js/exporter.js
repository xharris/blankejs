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

		
	}
}

document.addEventListener("openProject", function(e){
	app.removeSearchGroup("exporter");
	app.addSearchKey({key: 'Export game', onSelect: function() {
		new Exporter(app);
	}});
});