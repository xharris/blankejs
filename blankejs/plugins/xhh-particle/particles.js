Blanke.addPlugin((Blanke) => {
    let { GameObject, Canvas, Scene } = Blanke;

    class Particles extends GameObject {
        constructor () {
            super();
            this.canvas = new Canvas();
            this.canvas.auto_clear = false;
            this.graphic = null;

            Scene.addUpdatable(this);
            Scene.addDrawable(this.canvas._getPixiObjs()[0]);

            this.rate = 1;
            this.timer = 0;
        }
        _getPixiObjs () {
            return this.canvas._getPixiObjs();
        }
        update (dt) {
            if (this.timer > 0) this.timer -= dt;
            else if (this.rate > 0 && this.graphic) {
                this.canvas.draw(this.graphic)
            }
        }
    }

    return Particles
})