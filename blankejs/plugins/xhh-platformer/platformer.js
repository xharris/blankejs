
document.addEventListener('blankeLoaded',(e) => {
    let blanke = e.detail.Blanke;

    blanke.Entity.prototype.addPlatforming = (opt) => {
        console.log('what even',this);
    }
})