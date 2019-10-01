Blanke.addPlugin((Blanke) => {
    let { GameObject, Timer, Scene } = Blanke;

    class Particles extends GameObject {
        constructor () {
            super();
            this.container = new PIXI.ParticleContainer(10000, {
                scale: true,
                position: true,
                rotation: true,
                uvs: true,
                alpha: true
            });
            this.graphic = null;

            Scene.addUpdatable(this);
            Scene.addDrawable(this.container);
        }
        _getPixiObjs () {
            return [this.container];
        }
        set rate (v) {
            this._rate = v;
            if (!this.rate_timer)
                this.rate_timer = Timer.every(v, () => {
                    this.emit();
                })
            else
                this.rate_timer.t = v;
        }
        update (dt) {
            
        }
        emit () {
            //let tex = this.graphic.getTexture();
            let new_spr = this.graphic.getTexture();
            new_spr.x = this.graphic.x;
            new_spr.y = this.graphic.y;
            this.container.addChild(new_spr);
        }
    }

    return Particles
})