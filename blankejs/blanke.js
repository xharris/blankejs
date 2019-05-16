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

    function b(a){return a?(a^Math.random()*16>>a/4).toString(16):([1e7]+
        -1e3+
        -4e3+
        -8e3+
        -1e11).replace(/[018]/g,b)}
    function uuid(a){return a?(a^Math.random()*16>>a/4).toString(16):([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g,b)}

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
       
            let props = ['alpha','width','height'];
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

    /* -SPATIALHASH */
    class SpatialHash {
        constructor (size) {
            this.size = size;
            this.hash = {};
        }
        _hash (obj) {
            return Math.floor(obj.x/this.size)+','+Math.floor(obj.y/this.size);
        }
        // must have an x/y
        add (obj) {
            obj._spatialhashid = uuid();
            this.update(obj);
            return obj;
        }
        update (obj) {
            // remove from previous position
            if (obj._spatialhashlastkey)
                this.remove(obj, true);
            // set to current position
            let key = this._hash(obj);
            obj._spatialhashlastkey = key;
            if (this.hash[key] == undefined)
                this.hash[key] = {};
            this.hash[key][obj._spatialhashid] = obj;
        }
        remove (obj, temporary) {
            delete this.hash[obj._spatialhashlastkey][obj._spatialhashid];
            if (Object.values(this.hash[obj._spatialhashlastkey]).length == 0)
                delete this.hash[obj._spatialhashlastkey];
            // permanently removed
            if (!temporary) {
                delete obj._spatialhashid;
                delete obj._spatialhashlastkey;
            }
        }
        getNeighbors (obj) {
            let ret_objs = [];
            let x1 = Math.floor(obj.x/this.size)-1, x2 = Math.floor(obj.x/this.size)+1;
            let y1 = Math.floor(obj.y/this.size)-1, y2 = Math.floor(obj.y/this.size)+1;
            let key = '';
            for (let x = x1; x <= x2; x++) {
                for (let y = y1; y <= y2; y++) {
                    key = x+','+y;
                    if (this.hash[key]) {
                        ret_objs = ret_objs.concat(Object.values(this.hash[key]).filter(v => v._spatialhashid != obj._spatialhashid));
                    }
                }
            }
            return ret_objs;
        }
    }

    /* -HITBOX */
    class Hitbox {
        constructor (opt) {
            this.options = opt;
            switch (opt.type) {
                case 'circle':
                    this.world_obj = new SAT.Circle(new SAT.Vector(opt.shape[0], opt.shape[1]), opt.shape[2])
                    break;
                case 'rect':
                    this.world_obj = new SAT.Box(new SAT.Vector(opt.shape[0], opt.shape[1]), opt.shape[2], opt.shape[3]).toPolygon();
                    break;
                case 'poly':
                    let start_x = opt.shape[0];
                    let start_y = opt.shape[1];
                    this.world_obj = new SAT.Polygon(new SAT.Vector(start_x, start_y),
                            opt.shape.slice(2).reduce((result, point, p) => {
                                if ((p+1)%2 == 0) {
                                    result.push(new SAT.Vector(opt.shape[p]-start_x, opt.shape[p-1]-start_y));
                                }
                                return result;
                            },[])
                        )
            }
            // this.world_obj.set_collision_tags(opt.tag);
            this.response = new SAT.Response();
            this.world_obj.parent = this;
            this.type = opt.type;
            this.tag = opt.tag;

            this.graphics = new Draw(
                ['fill', Draw.red],
                ['rect', ...opt.shape],
                ['fill']
            );

            Hitbox.world.add(this);
            Scene.addUpdatable(this);
        }
        get x () { return this.world_obj.pos.x; }
        get y () { return this.world_obj.pos.y; }
        move (dx, dy) {
            this.world_obj.pos.add(new SAT.Vector(dx, dy));
            this.graphics.x += dx;
            this.graphics.y += dy;
        }
        position (x, y) {
            if (x!=null && y!=null) {
                this.world_obj.pos = new SAT.Vector(x, y);
                Hitbox.world.update(this);
                this.graphics.x = x;
                this.graphics.y = y;
            } else {
                return this.world_obj.pos;
            }
        }
        collisions () {
            let shapes = Hitbox.world.getNeighbors(this);
            let response;
            // only return neighbors that collide
            let collisions = shapes.reduce((arr, s) => {
                response = this.collides(s);
                if (response)
                    arr.push([s, response]);
                return arr;
            }, []);
            return collisions;
        }
        collides (other) {
            let shape_str = {'circle':'Circle', 'rect':'Polygon', 'poly':'Polygon'};
            this.response.clear()
            if (SAT['test'+shape_str[this.type]+shape_str[other.type]](this.world_obj, other.world_obj, this.response))
                return {
                    sep_vec: {x: this.response.overlapV.x, y: this.response.overlapV.y}
                };
        }
        repel (other, ...args) {
            this.world_obj.repel(other.world_obj, ...args);
            this.graphics.x = this.world_obj.x;
            this.graphics.y = this.world_obj.y;
        }
        destroy () {
            Hitbox.world.remove(this);
        }
    }
    Hitbox.world = new SpatialHash(Math.max(Game.width, Game.height)/2);

    /* -ENTITY */
    class Entity {
        constructor (...args) {
            this._x = 0;
            this._y = 0;
            this.hspeed = 0;
            this.vspeed = 0;
            this.gravity = 0;
            this.gravity_direction = 0;
            // sprite
            this.sprites = {};
            this.sprite_index = '';
            // collision
            this.shape_index = '';
            this.shapes = {};
            this.onCollide = {};

            let spr_props = ['alpha','width','height'];
            for (let p of spr_props) {
                Object.defineProperty(this,'sprite_'+p,{
                    get: () => {
                        if (this.sprite_index) {
                            return this.sprites[this.sprite_index][p];
                        }
                    },
                    set: (v) => {
                        for (let spr in this.sprites) {
                            this.sprites[this.sprite_index][p] = v;
                        }
                    }
                });
            }

            if (this.init) this.init(...args);

            this.xprevious = this.x;
            this.yprevious = this.y;
            Scene.addUpdatable(this);
        }
        _update (dt) {
            if (this.update)
                this.update(dt);
            let dx = this.hspeed, dy = this.vspeed;  
            // gravity
            if (this.gravity != 0) {
                dx += Util.direction_x(this.gravity_direction, this.gravity);
                dy += Util.direction_y(this.gravity_direction, this.gravity); 
            }
            // move shapes if x/y is different
            if (this.xprevious != this.x || this.yprevious != this.y) {
                for (let name in this.shapes) {
                    this.shapes[name].position(this.x, this.y);
                }
            }
            // collision
            let precoll_hspeed = this.hspeed, precoll_vspeed = this.vspeed;
            let resx = 0, resy = 0;
            
            for (let name in this.shapes) {
                let shape = this.shapes[name];
                shape.move(dx*dt, dy*dt);

                let coll_list = shape.collisions();
                if (coll_list && this.onCollide[name]) {
                    for (let info of coll_list) {
                        let res = info[1]
                        let cx = res.sep_vec.x, cy = res.sep_vec.y;
                        this.collisionStopX = () => {
                            resx += cx;
                            dx = 0;
                        }
                        this.collisionStopY = () => {
                            resy += cy;
                            dy = 0;
                        }
                        this.collisionStop = () => {
                            resx += cx;
                            resy += cy;
                            dx = 0, dy = 0;
                        }
                        this.onCollide[name](info[0], res);
                    }
                    delete this.collisionStopY;
                    delete this.collisionStopX;
                    delete this.collisionStop;
                }     
            }
            for (let name in this.shapes) {
                this.shapes[name].move(-resx, -resy);
            }
            // set position of entity
            if (this.shape_index) {
                let pos = this.shapes[this.shape_index].position();
                this.x = pos.x, this.y = pos.y;
            } else {
                this.x += dx * dt;
                this.y += dy * dt;
            }
            this.xprevious = this.x;
            this.ypreviuos = this.y;
            // preserve user-set speeds
            if (precoll_hspeed == this.hspeed) this.hspeed = dx;
            if (precoll_vspeed == this.vspeed) this.vspeed = dy;
        }
        addSprite (name) {
            this.sprites[name] = new Sprite(name);
            if (!this.sprite_index)
                this.sprite_index = name;
        }
        addShape (name, options) {
            options.tag = this.constructor.name + (options.tag ? '.'+options.tag : '');
            this.shapes[name] = new Hitbox(options);
            this.shapes[name].position(this.x, this.y);
            if (!this.shape_index)
                this.shape_index = name;
        }
        get sprite_index () { return this._sprite_index || ''; }
        set sprite_index (v) {
            this._sprite_index = v;
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
        if (keys_pressed[key] == false)
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
            if (keys_pressed[key] == true)
                press_check[key] = true;
        }
    }
    app.ticker.add(()=>{
        Input.inputCheck();
    },null,PIXI.UPDATE_PRIORITY.LOW);
    return {Asset, Draw, Entity, Game, Hitbox, Input, Scene, Sprite, Util};
}
