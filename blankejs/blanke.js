/*
Common class methods:
    _getPixiObjs() : if available, returns an array of DisplayObjects that is used for rendering
*/
var Blanke = (selector, options) => {
    let re_sep = /[\\\/]/;

    let blanke_ref = this;
    this.options = Object.assign({
        autofocus: true,
        width: 600,
        height: 400,
        resolution: 1,
        config_file: 'config.json'
    },options || {}); 
    // init PIXI
    let app;
    
    app = new PIXI.Application({
        width: this.options.width,
        height: this.options.height,
        resolution: this.options.resolution
    });
    PIXI.settings.SCALE_MODE = PIXI.SCALE_MODES[(this.options.scale_mode || 'nearest').toUpperCase()];
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
    if (this.options.autofocus) app.view.focus();

    const engineLoaded = () => {
        // load config.json
        Asset.add(this.options.config_file,'config',(data) => {
            if (data) {
                Game.config = JSON.parse(data);
            }
        });
    }

    const updateZOrder = (obj) => {
        let containers = [];
        if (obj._getPixiObjs) {
            let objs = obj._getPixiObjs();
            for (let o of objs) {
                let container = o.parent;
                o.zIndex = obj.z;
                if (!containers.includes(container))
                    containers.push(container);
            }
        }
        // sort the collected containers
        containers.forEach((cont) => {
            /*
            cont.children = quickSort(cont, (a,b)=>{
                return (a.zIndex || 0) < (b.zIndex || 0);
            })*/
            cont.sortableChildren = true;
            cont.sortChildren();
//                cont.sortDirty = true;
        })
    }

    const quickSort = (items, fn) => {
        fn = fn || function (a, b) { return a < b; };
        let countOuter = 0;
        let countInner = 0;
        let countSwap = 0;
        function _sort(array) {
            countOuter++;
            if(array.length < 2) {
              return array;
            }
          
            let pivot = array[0];
            let lesser = [];
            let greater = [];
          
            for(let i = 1; i < array.length; i++) {
              countInner++;
              if(fn(array[i], pivot)) { // array[i] < pivot) {
                lesser.push(array[i]);
              } else {
                greater.push(array[i]);
              }
            }
          
            return _sort(lesser).concat(pivot, _sort(greater));
        }
        return _sort (items);
    }

    //var cull = new Cull.SpatialHash();

    // UUID stuff
    function b(a){return a?(a^Math.random()*16>>a/4).toString(16):([1e7]+
        -1e3+
        -4e3+
        -8e3+
        -1e11).replace(/[018]/g,b)}
    function uuid(a){return a?(a^Math.random()*16>>a/4).toString(16):([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g,b)}

    /* -GAME */
    var Game = {
        config: {},
        get width () { return app.view.width; },
        get height () { return app.view.height; }
    };

    /* -UTIL */
    var Util = {
        // math
        rad: (deg) => deg * (Math.PI/180),
        deg: (rad) => rad * (180/Math.PI),
        direction_x: (angle, dist) => angle == 0 ? dist : Math.cos(Util.rad(angle)) * dist,
        direction_y: (angle, dist) => angle == 0 ? dist : Math.sin(Util.rad(angle)) * dist,
        distance: (x1, y1, x2, y2) => Math.sqrt(Math.pow((x2-x1),2)+Math.pow((y2-y1),2)),
        direction: (x1, y1, x2, y2) => Util.deg(Math.atan2(y2-y1,x2-x1)),
        // file
        basename: (path, no_ext) => no_ext == true ? path.split(re_sep).slice(-1)[0].split('.')[0] : path.split(re_sep).slice(-1)[0]
    }
    
    /* -ASSET */
    var Asset = {
        data: {},
        path_name: {},
        supported_filetypes: {
            /* options: { name, frames, frame_size, offset, columns } */
            'image':['png'],
            'map':['map']
        },
        base_textures: {},
        getType: (path) => {
            let parts = path.split('.');
            let ext = parts.pop();
            let name = Asset.parseAssetName(path);
            for (let type in Asset.supported_filetypes) {
                if (Asset.supported_filetypes[type].includes(ext))
                    return [type, name];
            }
            return ['file', Util.basename(name)];
        },
        parseAssetName: (path) => {
            return path.replace(/assets\/\w+\//,'').split('.').slice(0,-1).join('.');
        },
        // callback only used in : json
        add: (path, options={}, cb) => {
            // adding multiple
            if (Array.isArray(path)) {
                for (let ast of path) {
                    Asset.add(...ast);
                }
                return;
            }
            let [type, name] = Asset.getType(path);
            // default values
            if (type == 'image') {
                // IMAGE
                // NOTE: do NOT add frame_size as that is mandatory if it's an animated sprite
                options = Object.assign({
                    name: name,
                    offset: [0,0],
                    columns: 1,
                    frames: 1,
                    speed: 1
                }, typeof options === "string" ? {name:options} : (options || {}));
                name = options.name;
            } else {
                name =  typeof options === "string" ? options : (options.name || name)
            }
            let storeAsset = (_type,_path,_name, _data) => {
                if (!(_type && _path && _name)) return;
                if (!Asset.data[_type]) {
                    Asset.path_name[_type] = {};
                    Asset.data[_type] = {};
                }
                if (!Asset.path_name[_type][_path]) 
                    Asset.path_name[_type][_path] = []
                
                Asset.path_name[_type][_path].push(_name);   
                Asset.data[_type][_name] = _data;
            }
            switch (type) {
                // IMAGE / Animation IMAGE
                case 'image':
                    let img_obj = {path:path, animated:false, options:options};
                    // base texture
                    if (!Asset.base_textures[path])
                        Asset.base_textures[path] = PIXI.BaseTexture.from(path);
                    let base_tex = Asset.base_textures[path];
                    if (options && options.frame_size) {
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
                                [base_tex, x, y, w, h]
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
                    // crop texture frames
                    if (img_obj.frames)
                        img_obj.tex_frames = img_obj.frames.map( f => Asset.texCrop(f[0], f.slice(1)) );
                    
                    storeAsset(type, path, name, img_obj);
                    Asset.data[type][name] = img_obj;
                    return img_obj;
                    break;
                // FILE / MAP : json, text, file with data...
                case 'file':
                case 'map':
                    let prom = new Promise((res, rej)=>{
                        let xhr = new XMLHttpRequest();
                        xhr.onreadystatechange = () => {
                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                if (xhr.status === 200) {
                                    storeAsset(type, path, name, xhr.responseText);
                                    // success
                                    res(xhr.responseText);
                                } else {
                                    // error
                                    res(null);
                                }
                            }
                        }
                        xhr.open("GET",path,true);
                        xhr.send();
                    });
                    storeAsset(type, path, name, prom);
                    if (cb) 
                        prom.then(cb);
                    break;
            }
        },
        texCrop: (base_tex, dims) => {
            return new PIXI.Texture(base_tex, new PIXI.Rectangle(dims[0],dims[1],dims[2],dims[3]))
        },
        get: (type, name, cb) => {
            if (!(Asset.data[type] && Asset.data[type][name]))
                return;
            switch (type) {
                case 'image':
                    return Asset.data[type][name];
                    break;
                case 'file':
                case 'map':
                    let data = Asset.data[type][name];
                    if (typeof data.then == 'function') {
                        data.then(cb);
                    } else
                        cb(data);
            }
        },
        getName: (type, path) => {
            if (Asset.path_name[type] && Asset.path_name[type][path])
                return Asset.path_name[type][path];
            return [];
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
        _getPixiObjs () {
            return [this.graphics];
        }
        get x () { return this.graphics.x; }
        get y () { return this.graphics.y; }
        set x (v){ this.graphics.x = v; }
        set y (v){ this.graphics.y = v; }
        get visible () { return this.graphics.visible; }
        set visible (v){ this.graphics.visible = v; }
        draw (...args) {
            if (this.auto_clear)
                this.clear();
            for (let arg of args) {
                let name = Draw.functions[arg[0]] || arg[0];
                let params = arg.slice(1);
                if (name == 'beginFill' && params.length == 0) {
                    name = 'endFill';
                }
                if (name == 'beginTextureFill' && params.length == 0) {
                    name = "endFill";
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
        destroy () {
            this.graphics.destroy();
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
        fill:'beginFill',
        texture:'beginTextureFill'
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
            this.name = name;
            this.container = new PIXI.Container();
            this.objects = [];
            this.onStart = () => {};
            this.onUpdate = (dt) => {};
            this.onEnd = () => {};
            game_container.addChild(this.container);
        }

        _getPixiObjs () {
            return [this.container];
        }
    
        _onStart () {
            this.container.visible = true;
            this.onStart.call(this);
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
            this.onUpdate.call(this, dt);
            for (let obj of this.objects) {
                if (obj._update)
                    obj._update(dt);
                else if (obj.update)
                    obj.update(dt);
            }
        }

        start () {
            Scene.start(this.name);
        }
    }
    
    var Scene = (name, functions) => {
        if (!Scene.ref[name]) {
            Scene.ref[name] = new _Scene(name);
            // apply given callbacks
            for (let fn in functions) {
                Scene.ref[name][fn] = functions[fn].bind(Scene.ref[name],Scene.ref[name]);
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
        else
            game_container.addChild(obj);
    }

    Scene.addUpdatable = (obj) => {
        if (Scene.stack.length > 0) 
            Scene(Scene.stack[Scene.stack.length-1]).objects.push(obj);
        else
            Scene.stray_objects.push(obj);
    }
    // if a scene has not been createed
    Scene.stray_objects = [];
    app.ticker.add((dt) => {
        for (let obj of Scene.stray_objects) {
            if (obj._update)
                obj._update(dt);
            else if (obj.update)
                obj.update(dt);
        }
    });
    
    Scene.ref = {};
    Scene.stack = [];

    /* -SPRITE */
    class Sprite {
        constructor (name, options) {
            this.animated = false;
            let asset = Asset.get('image',name);
            // animated sprite
            if (asset.tex_frames) {
                this.animated = true;
                this.sprite = new PIXI.AnimatedSprite(asset.tex_frames);
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
       
            let props = ['alpha','width','height','pivot'];
            for (let p of props) {
                Object.defineProperty(this,p,{
                    get: () => this.sprite[p],
                    set: (v) => this.sprite[p] = v
                });
            }
        }
        _getPixiObjs () { return [this.sprite]; }
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
            this.size = size || 200;
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
        getArea (x, y, w, h) { 
            w = w || x;
            h = h || y;
            let ret_objs = [];
            for (let rx = x; rx <= w; rx += this.size) {
                for (let ry = y; ry <= h; ry += this.size) {
                    ret_objs = ret_objs.concat(this.getNeighbors({x:x,y:y}, true));
                }
            }
            return ret_objs;
        }
        getNeighbors (obj, include_given) {
            let ret_objs = [];
            let x1 = Math.floor(obj.x/this.size)-1, x2 = Math.floor(obj.x/this.size)+1;
            let y1 = Math.floor(obj.y/this.size)-1, y2 = Math.floor(obj.y/this.size)+1;
            let key = '';
            for (let x = x1; x <= x2; x++) {
                for (let y = y1; y <= y2; y++) {
                    key = x+','+y;
                    if (this.hash[key]) {
                        ret_objs = ret_objs.concat(
                            Object.values(this.hash[key])
                                  .filter(v => include_given || v._spatialhashid != obj._spatialhashid)
                        );
                    }
                }
            }
            return ret_objs;
        }
        getAll () {
            let ret_objs = [];
            for (let key in this.hash) {
                ret_objs = ret_objs.concat(Object.values(this.hash[key]));
            }
            return ret_objs;
        }
    }

    /* -HITBOX */
    class Hitbox {
        /* opt = {type (rect/circle/poly), shape, tag} */
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
                ['lineStyle', 2, Draw.red, 0.5, 0],
                ['fill', Draw.red, 0.3],
                ['rect', ...opt.shape],
                ['fill']
            );
            this.debug = false;  // TODO remove later

            Hitbox.world.add(this);
            Scene.addUpdatable(this);
        }
        set debug (v) { this.graphics.visible = v; }
        get debug () { return this.graphics.visible; }
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
            this.is_entity = true;
            this._x = 0;
            this._y = 0;
            this.hspeed = 0;
            this.vspeed = 0;
            this.gravity = 0;
            this.gravity_direction = 0;
            // collision
            this.shape_index = null;
            this.shapes = {};
            this.onCollide = {};
            // sprite
            this.sprites = {};
            this.sprite_index = '';
            let spr_props = ['alpha','width','height','pivot'];
            for (let p of spr_props) {
                Object.defineProperty(this,'sprite_'+p,{
                    get: () => {
                        if (this.sprites[this.sprite_index]) {
                            return this.sprites[this.sprite_index][p];
                        }
                        return 0;
                    },
                    set: (v) => {
                        for (let spr in this.sprites) {
                            this.sprites[this.sprite_index][p] = v;
                        }
                    }
                });
            }
            this.z = 0;
            if (this.init) this.init(...args);
            this.xprevious = this.x;
            this.yprevious = this.y;
            Scene.addUpdatable(this);
        }
        _getPixiObjs () {
            return Object.values(this.sprites).map(spr => spr.sprite);
        }
        set z (v) {
            this._z = v;
            updateZOrder(this);
        }
        get z () { return this._z; }
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
                shape.debug = this.debug;
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
                this.shapes[name].move(-resx*1.1, -resy*1.1);
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
            if (this.sprite_index == '')
                this.sprite_index = name;
        }
        addShape (name, options) {
            options.tag = this.constructor.name + (options.tag ? '.'+options.tag : '');
            this.shapes[name] = new Hitbox(options);
            this.shapes[name].position(this.x, this.y);
            if (!this.shape_index)
                this.shape_index = name;
        }
        get debug () { return this._debug; }
        set debug (v) { this._debug = v; }
        get sprite_index () { return this._sprite_index; }
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
        get y () { return this._y; }
        set x (v) {
            this._x = v;
            for (let s in this.sprites) {
                this.sprites[s].x = v + this.sprites[s].pivot.x;
            }    
        }
        set y (v) {
            this._y = v;
            for (let s in this.sprites) {
                this.sprites[s].y = v + this.sprites[s].pivot.y;
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
        if (blanke_ref.focused) e.preventDefault();
        else return;
        Input.press(e.key);
    });
    window.addEventListener('keydown',(e)=>{
        if (blanke_ref.focused) e.preventDefault();
        else return;
        Input.release(e.key);
    });
    var Input = (name) => {
        let ret = { pressed: false, released: false };
        let inputs = input_ref[name];
        if (!inputs) return;
        for (let i_str of inputs) {
            // multi-input?
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
    Input.press = (key) => {
        keys_pressed[key] = false;
        keys_released[key] = true;
        press_check[key] = false;
        release_check[key] = false;
    }
    Input.release = (key) => {
        if (keys_pressed[key] == false)
            press_check[key] = false;
        keys_pressed[key] = true;
        keys_released[key] = false;
    }
    app.ticker.add(()=>{
        Input.inputCheck();
    },null,PIXI.UPDATE_PRIORITY.LOW);

    /* -VIEW */
    let view_ref = {};
    class _View {
        constructor (name) {
            this.name = name;
            this.container = new PIXI.Container();
            this.bg_color = new PIXI.Sprite(PIXI.Texture.WHITE);
            this.bg_color.zIndex = -10000000000000;
            //this.background_color = Game.background_color;
            
            this.follow_obj = null;
            this.x = 0;
            this.y = 0;
            this.mask = new Draw();
            this.port_width = Game.width;
            this.port_height= Game.height;
            this._scale = new PIXI.Point(1,1);
            this.angle = 0;
            this._updateMask();
            this.container.addChild(this.bg_color);
            game_container.addChild(this.container);
        }
        set background_color (v) {
            this.bg_color.width = Game.width * 1.5;
            this.bg_color.height = Game.height * 1.5;
            this.bg_color.tint = v;
        }
        get background_color () {
            return this.bg_color.tint;
        }
        get x () { return this._x; }
        get y () { return this._y; }
        set x (v) { 
            if (this._last_x != this._x)
                ;//cull.cull(this.getBounds()); 
            this._last_x = this._x;
            this._x = v; 
        }
        set y (v) { 
            if (this._last_y != this._y)
               ;//cull.cull(this.getBounds()); 
            this._last_y = this._y;
            this._y = v; 
        }
        get port_width () { return this._port_width; }
        get port_height (){ return this._port_height; }
        set port_width (v) {
            if (this._last_port_width != this._port_width)
                ;//cull.cull(this.getBounds()); 
            this._last_port_width = this._port_width;
            this._port_width = v; 
        }
        set port_height (v) {
            if (this._last_port_height != this._port_height)
                ;//cull.cull(this.getBounds()); 
            this._last_port_height = this._port_height;
            this._port_height = v; 
        }
        getBounds () {
            return {
                x: this._x, y: this._y,
                width: this._port_width, height: this._port_height
            }
        }
        _updateMask () {
            this.mask.draw(
                ['fill',Draw.white],
                ['rect',
                    0,
                    0,
                    this.port_width,
                    this.port_height
                ],
                ['fill']
            );
            this.container.mask = this.mask.graphics;
        }
        get scale () {
            return this._scale;
        }
        follow (obj) { 
            if (this.follow_obj) {
                this.remove(this.follow_obj);
            }
            if (obj.x != null && obj.y != null) {
                this.follow_obj = obj;
                this.add(this.follow_obj)
            }
        }
        add (...objects) {
            for (let obj of objects) {
                if (!obj._getPixiObjs) return;

                let pixi_objs = obj._getPixiObjs();
                for (let o of pixi_objs) {
                    o._last_parent = o.parent;
                    o.setParent(this.container);
                }
            }
            this.container.sortChildren();
        }
        remove (...objects) {
            for (let obj of objects) {
                if (!obj._getPixiObjs) return;

                let pixi_objs = obj._getPixiObjs();
                for (let o of pixi_objs) {
                    if (o._last_parent) {
                        o.setParent = o._last_parent
                        o._last_parent = this.container;
                    }
                }
            }
        }
        destroy () {
            delete view_ref[this.name];
            for (let child of this.container.children) {
                child.setParent(child._last_parent);
                delete child._last_parent;
            }
            this.container.destroy();
        }
        update () {
            let x = this.x, y = this.y;
            let pw = this.port_width;
            let ph = this.port_height;
            let half_pw = pw / (2 * this.scale.x);
            let half_ph = ph / (2 * this.scale.y);
            let f_obj = this.follow_obj;
            if (f_obj) {
                x = -f_obj.x + half_pw;
                y = -f_obj.y + half_ph;
                if (f_obj.is_entity) {
                   x -= f_obj.sprite_pivot.x;
                   y -= f_obj.sprite_pivot.y;
                }
            }
            this.container.scale.copyFrom(this.scale);
            this.container.angle = this.angle;
            this.container.pivot.x = -x + half_pw;
            this.container.pivot.y = -y + half_ph;
            this.container.x = pw / 2;
            this.container.y = ph / 2;
        
            this.bg_color.x = -x - (half_pw);
            this.bg_color.y = -y - (half_ph);
            //this.bg_color.x = -x;
            //this.bg_color.y = -y;
            this.bg_color.angle = 0;//-this.angle;

            this.x = x;
            this.y = y;
            this._updateMask();
        }
    }
    var View = name => {
        if (!view_ref[name])
            view_ref[name] = new _View(name);
        return view_ref[name];
    }
    app.ticker.add(()=>{
        for (let name in view_ref) {
            view_ref[name].update();
        }
    },null,PIXI.UPDATE_PRIORITY.LOW+1);

    /* -MAP */
    let tex_
    class Map {
        constructor (name, from_file) {
            this.name = name;
            this.tile_hash = new SpatialHash();
            this.hitboxes = [];
            this.layers = []; // PIXI.Containers
            this.main_container = new PIXI.Container();

            if (!from_file)
                this.addLayer('layer0');

            Scene.addDrawable(this.main_container);
            Scene.addUpdatable(this);
            this._debug = false;
            this.z = 0;
        }
        set z (v) {
            this._z = v;
            updateZOrder(this);
        }
        get z () { return this._z; }
        set debug (v) {
            this._debug = v;
            for (let hitbox of this.hitboxes) {
                hitbox.debug = v;
            }
        }
        get debug () { return this._debug; }
        _getPixiObjs () { return [this.main_container]; }
        static load (name) { 
            return new Promise(res => {
                Asset.get('map',name,(data)=>{
                    data = JSON.parse(data);
                    let new_map = new Map(name, true);
                    // ** PLACE TILES **
                    for (let img_info of data.images) {
                        // get layer image belongs to
                        for (let lay_name in img_info.coords) {
                            let layer = new_map.getLayer(lay_name);
                            for (let c of img_info.coords[lay_name]) {
                                // place them
                                let asset_info = new_map.addTile(img_info.path, [c[0], c[1]], {
                                    offset: [c[2], c[3]],
                                    frame_size: [c[4], c[5]]
                                }, true)
                                // Map.config.tile_hitboxes
                                if (Array.isArray(Map.config.tile_hitboxes)) {
                                    let asset_name = Asset.parseAssetName(img_info.path);
                                    if (Map.config.tile_hitboxes.includes(asset_name)) {
                                        new_map.addHitbox({
                                            type: 'rect',
                                            shape: [c[0], c[1], c[4], c[5]],
                                            tag: asset_name
                                        })
                                    }
                                }
                            }
                        } 
                    }
                    // ** PLACE ENTITIES **
                    
                    new_map.redrawTiles();
                    res(new_map);
                });
            });
        }
        addLayer (name, _uuid) {
            let new_cont = new PIXI.Container();
            new_cont._uuid = _uuid || uuid();
            new_cont._name = name;
            new_cont._graphics = new Draw();
            new_cont._graphics._getPixiObjs()[0].setParent(new_cont);
            this.main_container.addChild(new_cont);
            this.layers.push(new_cont);
            return new_cont;
        }
        getLayer (name, is_uuid) {
            let ret_layer = this.layers.find((l) => is_uuid == true ? l._uuid = name : l._name == name);  
            if (!ret_layer)
                return this.addLayer(name);
            return ret_layer;
        }
        /*
            pos: [x, y, x, y, ...]
            opt: same options as Sprite (offset, frame_size)
        */
        addTile (name, pos, opt, skip_redraw) {
            if (opt.layer == null) opt.layer = this.layers[0]._name;
            // get the tile texture
            let key = [name.split('.')[0], opt.offset[0], opt.offset[1], opt.frame_size[0], opt.frame_size[1], opt.columns||0].join(',');
            let asset = Asset.get('image', key);
            if (!asset) {
                opt.name = key;
                opt.crop = true;
                asset = Asset.add(name, opt);
            }
            let tex_frames = asset.tex_frames;
            // place tiles
            for (let t = 0; t < pos.length; t += 2) {
                for (let f in tex_frames) {
                    this.tile_hash.add({
                        x: pos[t], y: pos[t+1],
                        w: tex_frames[f].width, h: tex_frames[f].height,
                        key: key, frame: parseInt(f), img_name: name,
                        layer: opt.layer
                    });
                }
            }
            // update graphics
            if (!skip_redraw) this.redrawTiles(opt.layer);
        } 
        redrawTiles (layer) {
            let tiles = this.tile_hash.getAll();
            let draw_instr = {}; // {layer: instructions}
            let tex;
            for (let tile of tiles) {
                if (!draw_instr[tile.layer])
                    draw_instr[tile.layer] = [];
                tex = Asset.get('image', tile.key);
                if (tex) {
                    let frame = tex.frames[tile.frame]
                    draw_instr[tile.layer].push(
                        ['texture', tex.tex_frames[tile.frame], 0xffffff, 1, new PIXI.Matrix(1,0,0,1,tile.x,tile.y)],
                        ['rect', tile.x, tile.y, tile.w, tile.h],
                        ['texture']
                    )
                }
            }
            // redraw all layers
            for (let l_name in draw_instr)
                this.getLayer(l_name)._graphics.draw(...draw_instr[l_name]);
        }
        removeTile (name, pos, layer) {
            let x, y;
            for (let t = 0; t < pos.length; t += 2) {
                x = pos[t]; y = pos[t+1];
                // get tiles in the area
                let tiles = this.tile_hash.getArea(x, y);
                for (let tile of tiles) {
                    if (name == tile.img_name && (!layer || layer == tile.layer) && x >= tile.x && y >= tile.y && x <= tile.x+tile.w && y <= tile.y+tile.h) {
                        // hit tile, remove it
                        this.tile_hash.remove(tile);
                    }
                }
            }
            // update graphics
            this.redrawTiles();
        }
        addHitbox (opt) {
            let hit = new Hitbox(opt)
            hit.debug = this.debug;
            this.hitboxes.push(hit);

        }
        addMarker (name, ...points) {
            this.markers[name] = points;
        }
    }
    Map.config = {};  // used during load()

    engineLoaded.call(this);
    return {Asset, Draw, Entity, Game, Hitbox, Input, Map, Scene, Sprite, Util, View};
}
