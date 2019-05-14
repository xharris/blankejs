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

    /* -GAME */
    var Game = {
        get width () { return app.view.width; },
        get height () { return app.view.height; }
    };

    /* -UTIL */
    var Util = {
        rad: (deg) => deg * (Math.PI/180),
        deg: (rad) => rad * (180/Math.PI),
        direction_x: (angle, dist) => Math.cos(Util.rad(angle)) * dist,
        direction_y: (angle, dist) => Math.sin(Util.rad(angle)) * dist,
        distance: (x1, y1, x2, y2) => Math.sqrt(Math.pow((x2-x1),2)+Math.pow((y2-y1),2)),
        direction: (x1, y1, x2, y2) => Util.deg(Math.atan2(y2-y1,x2-x1))
    }
    
    /* -ASSET */
    var Asset = {
        data: {},
        supported_filetypes: {
            'image':['png']
        },
        base_textures: {},
        getType: (path) => {
            let parts = path.split('.');
            let ext = parts.pop();
            let name = parts.join('.');
            for (let type in Asset.supported_filetypes) {
                if (Asset.supported_filetypes[type].includes(ext))
                    return [type, name];
            }
        },
        add: (path, options) => {
            let [type, name] = Asset.getType(path);
            if (type && !Asset.data[type])
                Asset.data[type] = {};
            switch (type) {
                case 'image':
                    let img_obj = {path:path, animated:false, options:options};
                    // base texture
                    if (!Asset.base_textures[path])
                        Asset.base_textures[path] = PIXI.BaseTexture.from(path);
                    let base_tex = Asset.base_textures[path];
                    if (options && options.frames) {
                        img_obj.animated = true;
                        img_obj.frames = [];
                        name = options.name;
                        // add regular image
                        Asset.add(path);
                        // get options
                        let offx = options.offset[0], offy = options.offset[1],
                        framew = options.frame_size[0], frameh = options.frame_size[1],
                        col = options.columns;
                        let x = offx, y = offy, w = framew, h = frameh;
                        // generate rectangles
                        for (let f = 0; f < options.frames; f++) {
                            img_obj.frames.push(
                                new PIXI.Texture(base_tex, new PIXI.Rectangle(x,y,w,h))
                            );
                            x += framew;
                            // next row?
                            if ((f % col) - 1 > col) {
                                x = offx;
                                y += frameh;
                            }                                
                        }
                    }
                    img_obj.texture = new PIXI.Texture(base_tex);
                    Asset.data[type][name] = img_obj;
                    break;
            }
        },
        get: (type, name) => {
            if (!(Asset.data[type] && Asset.data[type][name]))
                return;
            switch (type) {
                case 'image':
                    return Asset.data[type][name];//.clone();
                    break;
            }
        }
    }

    /* -DRAW
        Draw([args])

        Ex. // Draw a star
            new Draw([
                ['lineStyle', 2, 0xFFFFFF],
                ['fill', 0x35CC5A, 1],
                ['star', Game.width/2, Game.height/2, 5, 50],
                ['fill']
            ]);
     */
    class Draw {
        constructor (...args) {
            this.graphics = new PIXI.Graphics();
            this.auto_clear = true;
            Scene.addDrawable(this.graphics);
            this.draw(...args);
        }
        get x () { return this.graphics.x; }
        get y () { return this.graphics.y; }
        set x (v){ this.graphics.x = v; }
        set y (v){ this.graphics.y = v; }
        draw (...args) {
            if (this.auto_clear)
                this.clear();
            for (let arg of args) {
                let name = Draw.functions[arg[0]] || arg[0];
                let params = arg.slice(1);
                if (name == 'beginFill' && params.length == 0) {
                    name = 'endFill';
                }
                if (this.graphics[name])
                    this.graphics[name](...params);
                else
                    console.error(`${arg[0]} is not a Draw function`);
            }
        }
        clear () {
            this.graphics.clear();
        }
        // rgb to hex
        static hex (rgb) {
            let _hex = v => {
                let h = v.toString(16);
                return h.length == 1 ? '0' + h : h;
            }
            return '#'+_hex(rgb[0])+_hex(rgb[1])+_hex(rgb[2]);
        }
        // hex to rgb
        static rgb (hex) {
            var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
            return result ? [parseInt(result[1], 16), parseInt(result[2], 16), parseInt(result[3], 16)] : null;
        }
    }
    Draw.functions = {
        rect:'drawRect',
        star:'drawStar',
        fill:'beginFill'
    }
    Draw.colors = {
        red: 0xF44336, pink: 0xE91E63, purple: 0x673AB7,
        indigo: 0x3F51B5, baby_blue: 0x80D8FF, blue: 0x2196F3,
        dark_blue: 0x0C47A1, green: 0x4CAF50, yellow: 0xFFEB3B,
        orange: 0xFFC107, brown: 0x795548, gray: 0x9E9E9E,
        grey: 0x9E9E9E, black: 0x000000, white: 0xFFFFFF,
        black2: 0x212121,	       // but not actually black
        white2: 0xF5F5F5	   // but not actually white
    }
    for (let color in Draw.colors) {
        Draw[color] = Draw.colors[color];
    }

    /* -SCENE */
    class _Scene {
        constructor (name) {
            this.container = new PIXI.Container();
            this.objects = [];
            this.onStart = () => {};
            this.onUpdate = (dt) => {};
            this.onEnd = () => {};
            game_container.addChild(this.container);
        }
    
        _onStart () {
            this.container.visible = true;
            this.onStart();
            // start update loop
            app.ticker.add(this.update, this);
        }
    
        _onEnd () {
            app.ticker.remove(this.onUpdate, this);
            this.onEnd();
            for (let obj of this.objects) {
                if (obj._destroy)
                    obj._destroy();
                else if (obj.destroy)
                    obj.destroy();
            }
            this.container.visible = false;
            this.container.removeChildren();
        }
    
        update (dt) {
            this.onUpdate(dt);
            for (let obj of this.objects) {
                if (obj._update)
                    obj._update(dt);
                else if (obj.update)
                    obj.update(dt);
            }
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

    Scene.addUpdatable = (obj) => {
        if (Scene.stack.length > 0) 
            Scene(Scene.stack[Scene.stack.length-1]).objects.push(obj);
    }
    
    Scene.ref = {};
    Scene.stack = [];

    /* -SPRITE */
    class Sprite {
        constructor (name, options) {
            this.animated = false;
            
            let asset = Asset.get('image',name);
            // animated sprite
            if (asset.frames) {
                this.animated = true;
                this.sprite = new PIXI.AnimatedSprite(asset.frames);
                this.speed = asset.options.speed;
                this.sprite.play();
            }
            // static image
            else {
                this.sprite = new PIXI.Sprite(asset.texture);
            }
            Scene.addDrawable(this.sprite);

            this.sprite.x = 0;
            this.sprite.y = 0;
       
            let props = ['alpha'];
            for (let p of props) {
                Object.defineProperty(this,p,{
                    get: () => this.sprite[p],
                    set: (v) => this.sprite[p] = v
                });
            }
        }
        get x () { return this.sprite.x; }
        set x (v){ this.sprite.x = Math.floor(v); }
        get y () { return this.sprite.y; }
        set y (v){ this.sprite.y = Math.floor(v); }

        get speed () { if (this.animated) return this.sprite.animationSpeed; }
        set speed (v){ if (this.animated) this.sprite.animationSpeed = v; }
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

    /* -HITBOX */
    class Hitbox {
        constructor (opt) {
            this.options = opt;
            switch (opt.type) {
                case 'circle':
                    this.world_obj = Hitbox.world.add(
                        new SSCD.Circle(new SSCD.Vector(opt.shape[0], opt.shape[1]), opt.shape[2])
                    );
                    break;
                case 'rect':
                    this.world_obj = Hitbox.world.add(
                        new SSCD.Rectangle(
                            new SSCD.Vector(opt.shape[0], opt.shape[1]),
                            new SSCD.Vector(opt.shape[2], opt.shape[3])
                        )
                    );
                    break;
                case 'poly':
                    this.world_obj = Hitbox.world.add(
                        new SSCD.LineStrip(
                            ...opt.shape.reduce((result, point, p) => {
                                if ((p+1)%2 == 0) {
                                    result.push(new SSCD.Vector(opt.shape[p], opt.shape[p-1]));
                                }
                                return result;
                            },[]),
                            true
                        )
                    )
            }
            // this.world_obj.set_collision_tags(opt.tag);
            this.world_obj.parent = this;
            this.tag = opt.tag;
            this.graphics = new Draw(
                ['fill', Draw.red],
                ['rect', ...opt.shape],
                ['fill']
            );
            Scene.addUpdatable(this);
        }
        move (dx, dy) { this.world_obj.move(new SSCD.Vector(dx, dy)); }
        position (x, y) {
            if (x!=null && y!=null) {
                this.world_obj.set_position(new SSCD.Vector(x, y));
                this.graphics.x = x;
                this.graphics.y = y;
            } else {
                return this.world_obj.get_position();
            }
        }
        collisions () {
            let coll = Hitbox.world.pick_object(this.world_obj)
            return coll ? coll.parent : null;
        }
        repel (other, ...args) {
            this.world_obj.repel(other.world_obj, ...args);
            this.graphics.x = this.world_obj.x;
            this.graphics.y = this.world_obj.y;
        }
        destroy () {
            Hitbox.world.remove(this.world_obj);
        }
    }
    Hitbox.world = new SSCD.World({ grid_size: 400 });

    /* -ENTITY */
    class Entity {
        constructor (...args) {
            this._x = 0;
            this._y = 0;
            this.hspeed = 0;
            this.vspeed = 0;
            // sprite
            this.sprites = {};
            this.sprite_index = '';
            // collision
            this.shape_index = '';
            this.shapes = {};
            this.onCollide = {};

            Scene.addUpdatable(this);

            if (this.init) this.init(...args);
        }
        _update (dt) {
            let dx = 0, dy = 0;
            // gravity
            this.hspeed += Util.direction_x(this.gravity_direction, this.gravity);
            this.vspeed += Util.direction_y(this.gravity_direction, this.gravity);
            // movement
            dx += this.hspeed;
            dy += this.vspeed;
            if (this.update)
                this.update(dt);
            // collision
            for (let name in this.shapes) {
                let move_shape = true;  // sync shape with player position?
                let shape = this.shapes[name];
                let collision = shape.collisions();
                if (collision && this.onCollide[name]) {
                    this.collisionStopY = () => {
                        move_shape = false;
                        //collision.repel(shape, dy, 5);
                        dy = 0;
                        let new_pos = shape.position();
                        this.y = new_pos.y;    
                    }
                    this.onCollide[name](collision);
                }
                // no collision
                shape.position(this.x, this.y);     
            }
            this.x += dx * dt;
            this.y += dy * dt;
        }
        addSprite (name) {
            this.sprites[name] = new Sprite(name);
            if (!this.sprite_index)
                this.sprite_index = name;
        }
        addShape (name, options) {
            options.tag = this.constructor.name + (options.tag ? '.'+options.tag : '');
            this.shapes[name] = new Hitbox(options);
            if (!this.shape_index)
                this.shape_index = name;
        }
        set sprite_index (v) {
            // don't show other sprites
            for (let n in this.sprites) {
                this.sprites[n].visible = false;
            }
            // show given sprites
            if (Array.isArray(v)) {
                for (let i of v) {
                    if (this.sprites[i])
                        this.sprites[i].visible = true;
                }
            }
            else if (this.sprites[v]) 
                this.sprites[v].visible = true;
        }
        get x () { return this._x; }
        set x (v) {
            this._x = v;
            for (let s in this.sprites) {
                this.sprites[s].x = v;
            }    
        }
        get y () { return this._y; }
        set y (v) {
            this._y = v;
            for (let s in this.sprites) {
                this.sprites[s].y = v;
            }    
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
    let input_options = {};
    let press_check = {};
    let release_check = {}; // { 'ArrowLeft': false, 'a': true }
    window.addEventListener('keyup',(e)=>{
        let key = e.key;
        keys_pressed[key] = false;
        keys_released[key] = true;
        press_check[key] = false;
        release_check[key] = false;
    });
    window.addEventListener('keydown',(e)=>{
        let key = e.key;
        press_check[key] = false;
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
                if (!keys_pressed[i_part] || (input_options[name].can_repeat == false && press_check[i_part] == true))
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
        if (['set','inputCheck'].includes(name)) return;
        let inputs = [];
        for (let i of input) {
            if (key_translation[i])
                inputs.push(key_translation[i]);
            else
                inputs.push(i);
        }
        input_ref[name] = inputs;
        input_options[name] = {};

        Object.defineProperty(Input,name,{
            get: () => input_options[name]
        })
    };
    Input.inputCheck = () => {
        for (let key in keys_released) {
            // released is only true once
            if (release_check[key] == false && keys_released[key] == true) {
                release_check[key] = true;
                keys_released[key] = false;
            }
        }
        for (let key in keys_pressed) {
            // for can_repeat
            if (keys_pressed[key] == true && press_check[key] == false) {
                press_check[key] = true;
            }
        }
    }
    app.ticker.add(()=>{
        Input.inputCheck();
    },null,PIXI.UPDATE_PRIORITY.LOW);
    return {Asset, Draw, Entity, Game, Hitbox, Input, Scene, Sprite};
}
