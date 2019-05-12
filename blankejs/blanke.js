var Blanke = (selector, options) => {
    this.options = options || {}; // TODO change to table.update or whataever
    // init PIXI
    let app = new PIXI.Application({
        width:200,
        height:200,
        resolution: 1
    });
    document.querySelector(selector).appendChild(app.view);
    // add main container for game
    let game_container = new PIXI.Container();
    app.stage.addChild(game_container);
    
    /* -ASSET */
    class Asset {
        static getType(path) {
            let parts = path.split('.');
            let ext = parts.pop();
            let name = parts.join('.');
            for (let type in Asset.supported_filetypes) {
                if (Asset.supported_filetypes[type].includes(ext))
                    return [type, name];
            }
        }
        static add (path) {
            let [type, name] = Asset.getType(path);
            if (type && !Asset.data[type])
                Asset.data[type] = {};
            switch (type) {
                case 'image':
                    Asset.data[type][name] = PIXI.Texture.from(path);
                    break;
            }
        }
        static get (type, name) {
            if (!(Asset.data[type] && Asset.data[type][name]))
                return;
            switch (type) {
                case 'image':
                    return Asset.data[type][name].clone();
                    break;
            }
        }
    }
    
    Asset.data = {};
    Asset.supported_filetypes = {
        'image':['png']
    }

    /* -SCENE */
    class _Scene {
        constructor (name) {
            this.container = new PIXI.Container();
            this.onStart = () => {};
            this.onEnd = () => {};
            game_container.addChild(this.container);
        }
    
        _onStart () {
            this.onStart();
        }
    
        _onEnd () {
            this.onEnd();
            this.container.destroy();
        }
    
        update () {
    
        }
    }
    
    var Scene = (name, functions) => {
        if (!Scene.ref[name]) {
            Scene.ref[name] = new _Scene(name);
            // apply given callbacks
            for (let fn in functions) {
                Scene.ref[name][fn] = functions[fn];
            }
        }
        return Scene.ref[name];
    }
    
    Scene.start = (name) => {
        // if the scene is already running, end it
        if (Scene.ref[name].active)
            Scene.end(name);
        // start it
        Scene.stack.push(name);
        Scene.ref[name]._onStart();
    }
    
    Scene.end = (name) => {
        let index = Scene.stack.indexOf(name);
        if (index > -1)
            Scene.stack.splice(index,1);
        Scene.ref[name]._onEnd();
    }
    
    Scene.endAll = () => {
        for (let s in Scene.stack) {
            Scene.stack[s]
        }
    }
    
    Scene.addDrawable = (obj) => {
        if (Scene.stack.length > 0)
            Scene(Scene.stack[Scene.stack.length-1]).container.addChild(obj);
    }
    
    Scene.ref = {};
    Scene.stack = [];

    /* -SPRITE */
    class Sprite {
        constructor (name, options) {
            this.x = 0;
            this.y = 0;
            this.animated = false;
            
            if (name)
                this.sprite = new PIXI.Sprite(Asset.get('image',name));
            // animated sprite
            if (options && options.speed) {
                this.animated = true;
                let tx_clones = [];
                // get cropped textures for sprite sheet
                // ...
                this.sprite = PIXI.extras.AnimatedSprite(tx_clones);
            }
            Scene.addDrawable(this.sprite);

            this.sprite.x = 0;
            this.sprite.y = 0;
        }
    
        crop (x, y, w, h) {
            /*
                // copy texture
                new_texture.frame = new Rectangle(x,y,w,h);
                let new_sprite = new Sprite();
                new_sprite.texture = new_texture;
                return new_sprite;
            */
        }
    }

    return {Asset, Scene, Sprite};
}
