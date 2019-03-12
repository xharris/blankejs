class TestView extends Editor {
	constructor (...args) {
		super(...args);

		this.setupDragbox();
		this.setTitle("Test View");
		this.removeHistory();

		this.container.width = 400;
		this.container.height = 350;

		this.el_blankelist = new BlankeListView();
		this.appendChild(this.el_blankelist.container);
	}
}

document.addEventListener('openProject',()=>{
	new TestView();
});