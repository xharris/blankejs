
document.addEventListener('blankeLoaded',(e) => {
    let blanke = e.detail.Blanke;

    blanke.Entity.addPlatforming = () => {
        console.log('what even');
    }
})