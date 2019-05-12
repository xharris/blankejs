var Blanke = (selector, options) => {
    let blanke_ref = this;
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
    // focus/blur events
    this.focused = false;
    app.view.tabIndex=-1;
    app.view.style.outline="none";
    app.view.addEventListener('focus',(e)=> {
        blanke_ref.focused = true;
    });
    app.view.addEventListener('blur',(e)=> {
        blanke_ref.focused = false;
    });
    
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
                    return Asset.data[type][name];//.clone();
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
            this.onUpdate = (dt) => {};
            this.onEnd = () => {};
            game_container.addChild(this.container);
        }
    
        _onStart () {
            this.onStart();
            // start update loop
            app.ticker.add(this.onUpdate, this);
        }
    
        _onEnd () {
            app.ticker.remove(this.onUpdate, this);
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
                Scene.ref[name][fn] = functions[fn].bind(Scene.ref[name]);
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

        get x () { return this.sprite.x };
        get y () { return this.sprite.y };
        set x (v) { if (this.sprite) this.sprite.x = v; }
        set y (v) { if (this.sprite) this.sprite.x = v; }
    
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

    /* -INPUT */
    let key_translation = {
        'down':'ArrowDown',
        'left':'ArrowLeft',
        'right':'ArrowRight',
        'up':'ArrowUp'
    };
    let keys_pressed = {};  // { 'ArrowLeft': true, 'a': false }
    let keys_released = {}; // ...
    let input_ref = {};     // { bob: ['left','a'] }
    let release_check = {}; // { 'ArrowLeft': false, 'a': true }
    window.addEventListener('keyup',(e)=>{
        let key = e.key;
        keys_pressed[key] = false;
        keys_released[key] = true;
        release_check[key] = false;
    });
    window.addEventListener('keydown',(e)=>{
        let key = e.key;
        keys_pressed[key] = true;
        keys_released[key] = false;
    });
    var Input = (name) => {
        let ret = { pressed: false, released: false };
        let inputs = input_ref[name];
        if (!inputs) return;
        for (let i_str of inputs) {
            // multi-inputs?
            let i_list = i_str.split('+');
            let all_pressed = true;
            let all_released = true;
            for (let i_part of i_list) {
                if (!keys_pressed[i_part])
                    all_pressed = false;
                if (!keys_released[i_part])
                    all_released = false;
            }
            if (all_pressed)
                ret.pressed = true;
            if (all_released)
                ret.released = true;
        }
        return ret;
    };
    Input.set = (name, ...input) => {
        let inputs = [];
        for (let i of input) {
            if (key_translation[i])
                inputs.push(key_translation[i]);
            else
                inputs.push(i);
        }
        input_ref[name] = inputs;
    };
    Input.releaseCheck = () => {
        for (let key in keys_released) {
            if (release_check[key] == false && keys_released[key] == true) {
                release_check[key] = true;
                keys_released[key] = false;
            }
        }
    }
    app.ticker.add(()=>{
        Input.releaseCheck();
    },null,PIXI.UPDATE_PRIORITY.LOW);
    return {Asset, Input, Scene, Sprite};
}
