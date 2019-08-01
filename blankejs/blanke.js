/*
Common class methods:
    _getPixiObjs() : if available, returns an array of DisplayObjects that is used for rendering

Todo:
NEED
    C Audio
    - Asset (font)
    C Effect
    C Input (mouse)
    - Window
PLUGINS
    - Net ?
    - Gamepad
    - Particle
    - Tween
    - Bezier
    - Physics
    - Steam
    - UI
*/
var Blanke = (selector, options) => {
    let re_sep = /[\\\/]/;
    let re_no_ext = /([\/\\\.]*[\w\/\\]+)/;
/*
    let elec, nwOS, eWin;
    if (typeof require === 'function' && require('electron')) {
        elec = require('electron');
        nwOS = require('os');
        eWin = elec.remote.getCurrentWindow();
    }
*/

    let blanke_ref = this;
    this.options = Object.assign({
        auto_focus: true,
        width: 600,
        height: 400,
        resizable: false,
        resolution: 1,
        config_file: 'config.json',
        fill_parent: false,
        auto_resize: false,
        ide_mode: false,
        root: null,
        background_color: null,
        scale_mode: 'nearest',
        round_pixels: true,
        fps: 60,
        assets: [],
        config: null,
        onLoad: () => {}
    },options || {}); 
    // init PIXI
    let app;
    let parent = document.querySelector(selector);
    
    PIXI.utils.skipHello();
    app = new PIXI.Application({
        width: this.options.width,
        height: this.options.height,
        resolution: this.options.resolution,
        resizeTo: this.options.fill_parent == true ? parent : null,
        backgroundColor: this.options.ide_mode ? 0x485358 : this.options.backgroundColor
    });
    PIXI.settings.TARGET_FPMS = this.options.fps / 1000;
    PIXI.settings.ROUND_PIXELS = this.options.round_pixels;
    PIXI.settings.SCALE_MODE = PIXI.SCALE_MODES[this.options.scale_mode.toUpperCase()];
    //parent.innerHTML = "";
    parent.appendChild(app.view);
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
    if (this.options.auto_focus) app.view.focus();
    // resize with parent
    if (this.options.auto_resize) {
        app.renderer.resize(parent.clientWidth, parent.clientHeight);
        window.addEventListener('resize',function(){
            app.renderer.resize(parent.clientWidth, parent.clientHeight);
            if (app.stage.hitArea) {
                app.stage.hitArea.width = Game.width;
                app.stage.hitArea.height = Game.height;
            }
        });
    }

    const removeSnaps = () => {
        // remove any pause image
        let old_img = app.view.parentNode.querySelector("#game-snap");
        if (old_img)
            old_img.remove();
    }

    const engineLoaded = () => {
        removeSnaps();
        Game.time = 0;
        Game.ide_mode = this.options.ide_mode;
        // load config.json
        if (this.options.config != null) {
            Game.config = this.options.config;
        }
        // update Map.obj_uuid
        if (Game.config.scene) {
            for (let uuid in Game.config.scene.objects) {
                Map.obj_uuid[Game.config.scene.objects[uuid].name] = uuid;
            }
        }
        Asset.add(this.options.assets);
        Asset.load(() => {
            if (this.options.onLoad)
                this.options.onLoad(classes);
            if (Game.config.first_scene && Scene.stack.length == 0) {
                Scene.start(Game.config.first_scene);
            }
        })
        // default fullscreen shortcut (NOT WORKING)
        Input.set('toggle-fullscreen','Alt Enter');
        empty_sprite = new Sprite({ no_scene : true });
    }

    const addZOrdering = (obj) => {
        Object.defineProperty(obj,'z',{
            get: function () { return this._z; },
            set: function (v)  {
                this._z = v;
                updateZOrder(this);
            }
        })
        obj.z = 0;
    }

    const updateZOrder = (obj) => {
        let containers = [];
        if (obj._getPixiObjs) {
            let objs = obj._getPixiObjs();
            for (let o of objs) {
                let container = o.parent;
                o.zIndex = obj.z;
                if (container && !containers.includes(container))
                    containers.push(container);
            }
        }
        // sort the collected containers
        containers.forEach((cont) => {
            cont.sortableChildren = true;
            cont.sortChildren();
        })
    }

    // Pixi object
    const replaceChild = (child, new_child) => {
        let parent = child.parent;
        if (parent) {
            child.destroy();
            new_child.setParent(parent);
        }
    }

    // Blanke object
    const setNewParent = (child, parent_container) => {
        if (!child._getPixiObjs) return false;

        let pixi_objs = child._getPixiObjs();
        for (let o of pixi_objs) {
            o._last_parent = o.parent;
            o.setParent(parent_container);
        }
        return true;
    }

    const restorePrevParent = (child) => {
        if (!child._getPixiObjs) return false;

        let pixi_objs = child._getPixiObjs();
        for (let o of pixi_objs) {
            if (o._last_parent) {
                let curr_parent = o.parent;
                o.setParent = o._last_parent
                o._last_parent = curr_parent;
            }
        }
        return true;
    }

    const aliasProps = (parent, child, props) => {
        for (let p of props) {
            Object.defineProperty(parent,p,{
                get: function () { return child[p] }, 
                set: function (v) { child[p] = v }
            });
        }
    }

    // hitbox (hitArea)
    const enableRect = (obj, getRect) => {
        if (obj.hasOwnProperty('rect')) return;
        Object.defineProperty(obj,'rect',{
            get: function() {
                if (getRect) return getRect();
                return obj.hitArea;
            }
        })
    }

    const enableEffects = (obj) => {
        if (obj.hasOwnProperty('effect')) return;
        Object.defineProperty(obj,'effect',{
            get: function() {
                if (!obj._effect) 
                    obj._effect = new EffectManager(obj);
                return obj._effect.effects;
            },
            set: function(v) {
                if (!obj._effect) 
                    obj._effect = new EffectManager(obj);
                obj._effect.add(v);
            }
        })
    }

    const storeInstance = (c,i) => {
        if (!c._instances) c._instances = [];
        c._instances.push(i);
    }

    const quickSort = (items, fn) => {
        fn = fn || function (a, b) { return a < b; };
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
        paused: false,
        config: {},
        time: 0,
        ms: 0,
        get os () { // ide, win, mac, linux, android, ios
            if (blanke_ref.options.ide_mode) return 'ide';
            let os_list = ['win','mac','linux','android'];
            let u_agent = navigator.userAgent.toLowerCase();
            for (let d of os_list) {
                if (u_agent.includes(d))
                    return d;
            }
            if (/ipad|iphone|ipod/i.test(u_agent))
                return 'ios';
            return '?';
        },
        get width () { return blanke_ref.options.resizeable ? app.view.width : blanke_ref.options.width; },
        get height () { return blanke_ref.options.resizable ? app.view.height : blanke_ref.options.height; },
        get background_color () { return app.renderer.backgroundColor; },
        set background_color (v) { app.renderer.backgroundColor = v; },
        // replaces the game with a screenshot
        paused: false,
        pause: () => {
            Game.paused = true;
            app.ticker.stop();
            if (Game.onPause) Game.onPause();
        },
        resume: () => {
            Game.paused = false;
            app.ticker.start();
            if (Game.onPause) Game.onPause();
        },
        step: () => {
            /*
            app.ticker.update(performance.now());
            app.renderer.render(app.stage);
            */
            if (Game.paused) {
                Game.resume()
                app.ticker.addOnce(()=>{
                    Game.pause();
                },null,PIXI.UPDATE_PRIORITY.UTILITY);
            }
        },
        freeze: () => {
            if (Game.frozen) return;
            Game.frozen = true;

            removeSnaps();
            let new_rtex = PIXI.RenderTexture.create(Game.width, Game.height);
            app.renderer.render(game_container, new_rtex);
            let el_img = app.renderer.extract.image(new_rtex);
            el_img.id = "game-snap";
            parent.appendChild(el_img);
            app.stop();
            app.view.style.display = "none";
        },
        unfreeze: () => {
            if (!Game.frozen) return;
            Game.frozen = false;

            if (!app) return;
            removeSnaps();
            app.start();
            app.view.style.display = "initial";
        },
        get fullscreen () {
            if (Game.os != 'ide')
                return document.fullscreen;
            return false;
        },
        set fullscreen (v) {
            if (Game.os != 'ide') {
                let c = app.view;
                if (v) {
                    (
                        c.requestFullscreen ||
                        c.mozRequestFullScreen ||
                        c.webkitRequestFullScreen ||
                        c.msRequestFullscreen || 
                        function () {throw new Error("Can't enter fullscreen!")}
                    ).call(c);
                } else {
                    (
                        document.exitFullscreen ||
                        document.mozCancelFullScreen || 
                        document.webkitCancelFullScreen ||
                        document.msExitFullscreen || 
                        function () {throw new Error("Can't leave fullscreen!")}
                    ).call(document);
                }
            }
        },
        end: () => { 
            if (!app) return;
            removeSnaps();
            Game.resume();
            // destroy scenes
            Scene.endAll();
            Scene.ref = {};
            // remove leftover game objects 
            for (let obj of Scene.stray_objects) {
                if (obj._destroy)
                    obj._destroy();
                else if (obj.destroy)
                    obj.destroy();
            }
            game_container.removeChildren();
            // reset input stuff
            input_ref = {};
        },
        destroy: () => { app.destroy(true); }
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
        // rand_range -> int [min,max)
        rand_range: (min, max) => Math.floor(Math.random() * (max - min)) + min,
        rand_choose: (arr) => arr[Util.rand_range(0,arr.length)],
        lerp: (a, b, amt) => a + amt * (b - a),
        sinusoidal: (min, max, spd, off=0) => min + -Math.cos(Util.lerp(0,Math.PI/2,off) + Game.time * spd) * ((max - min)/2) + ((max - min)/2), 
        // string
        str_count: (string, subString, allowOverlapping) => {
            // author: Vitim.us https://gist.github.com/victornpb/7736865
            string += "";
            subString += "";
            if (subString.length <= 0) return (string.length + 1);

            var n = 0,
                pos = 0,
                step = allowOverlapping ? 1 : subString.length;

            while (true) {
                pos = string.indexOf(subString, pos);
                if (pos >= 0) {
                    ++n;
                    pos += step;
                } else break;
            }
            return n;
        },
        // file
        basename: (path, no_ext) => no_ext == true ? path.split(re_sep).slice(-1)[0].split('.')[0] : path.split(re_sep).slice(-1)[0]
    }
    app.ticker.add((dt)=>{
        Game.time += dt;
        Game.ms += app.ticker.elapsedMS;
        if (Input('toggle-fullscreen').released) {
            Game.fullscreen = !Game.fullscreen;
        }
    });
    
    /* -ASSET */
    var Asset = {
        data: {},
        path_name: {},
        loader: new PIXI.Loader(),
        supported_filetypes: {
            /* options: { name, frames, frame_size, offset, columns } */
            'image':['png'],
            'audio':['wav'],
            'map':['map']
        },
        base_textures: {},
        getType: (path) => {
            let parts = path.split('.');
            let ext = parts.pop();
            let name = Asset.parseAssetName(path);
            for (let type in Asset.supported_filetypes) {
                if (Asset.supported_filetypes[type].includes(ext))
                    return [type, Util.basename(name)];
            }
            return ['file', Util.basename(name)];
        },
        parseAssetName: (path) => {
            return path.replace(/[\w_\\.-\/]+\/assets\/\w+\//,'').split('.').slice(0,-1).join('.');
        },
        // callback only used in : json
        add: (orig_path, options={}) => {
            // adding multiple
            if (Array.isArray(orig_path)) {
                for (let ast of orig_path) {
                    Asset.add(...ast);
                }
                return;
            }
            let path = (this.options.root ? this.options.root + '/' : '') + orig_path;
            let [type, name] = Asset.getType(path);
            if (Asset.data[type] && Asset.data[type][name]) return;

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
            // add it to loader
            Asset.loader.add(name, path, {metadata:{type:type, options:options}}, Asset._onComplete);
        },
        _onComplete: (info) => {
            let type = info.metadata.type;
            let data = info.data;
            let name = info.name;
            let options = info.metadata.options;
            let path = info.url;
            
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
                    if (!Asset.base_textures[path]) {
                        Asset.base_textures[path] = info.texture.baseTexture;// PIXI.BaseTexture.from(path, {crossorigin:false});
                    }
                    let base_tex = Asset.base_textures[path];
                    
                    if (options && options.frame_size) {
                        img_obj.animated = true;
                        name = options.name;
                        options.from_asset = true;
                        // crop texture frames
                        let result = Asset.texCrop(path, options, base_tex);
                        img_obj.frames = result.frames;
                        img_obj.tex_frames = result.tex_frames;
                    }
                    img_obj.texture = info.texture;// new PIXI.Texture(base_tex);
                    storeAsset(type, path, name, img_obj);
                    Asset.data[type][name] = img_obj;
                    return img_obj;
                    break;
                // FILE / MAP : json, text, file with data...
                case 'file':
                case 'map':
                    storeAsset(type, path, name, data);
                    break;
                // AUDIO
                case 'audio':
                    storeAsset(type, path, name, new Howl({src:[path]}));
                    break;
            }
        },
        audioSprite: (name, sprites) => {
            let path = Asset.getPath('audio',name)
            if (!path) return;
            let new_audio = new Howl({src:[path], sprite:sprites});
            Asset.data.audio[name] = new_audio;
            return new_audio;
        },
        tex_crop_cache: {},
        texCrop: (path, opt, base_tex) => {
            opt = Object.assign({
                offset: [0,0],
                spacing: [0,0],
                columns: 1,
                frames: 1,
                speed: 1,
                is_key: false,
                from_asset: false,
            }, opt);
            let real_path = Asset.getPath('image', path);
            if (real_path) 
                path = real_path;
            else if (!opt.from_asset) 
                path = (this.options.root ? this.options.root + '/' : '') + path;
            if (opt.is_key) 
                return Asset.tex_crop_cache[path];
            if (!base_tex) {
                // use supplied name
                if (!Asset.base_textures[path]) {
                    Asset.base_textures[path] = PIXI.BaseTexture.from(path, {crossorigin:false})
                }
                base_tex = Asset.base_textures[path]
            }
            let key = [path.match(re_no_ext)[1], opt.offset[0], opt.offset[1], opt.frame_size[0], opt.frame_size[1], opt.columns||0].join(',');
            if (!Asset.tex_crop_cache[key]) {
                // get options
                let offx = opt.offset[0], offy = opt.offset[1];
                let framew = opt.frame_size[0], frameh = opt.frame_size[1];
                let spacingx = opt.spacing[0], spacingy = opt.spacing[1];
                let col = opt.columns;
                let x = offx, y = offy, w = framew, h = frameh;
                let frames = [];
                // generate rectangles
                for (let f = 0; f < opt.frames; f++) {
                    frames.push(
                        [x, y, w, h]
                    );
                    x += framew + spacingx;
                    // next row?
                    if ((f % col) - 1 > col) {
                        x = offx;
                        y += frameh + spacingy;
                    }                                
                }
                Asset.tex_crop_cache[key] = {
                    key: key,
                    frames: frames,
                    tex_frames: frames.map(dims => new PIXI.Texture(base_tex, new PIXI.Rectangle(dims[0], dims[1], dims[2], dims[3])))
                }
            }
            return Asset.tex_crop_cache[key];
        },
        load: (cb) => {
            Asset.loader.onComplete.add(cb)
            Asset.loader.load();
        },
        get: (type, name) => {
            if (!(Asset.data[type] && Asset.data[type][name]))
                return;
            return Asset.data[type][name];
        },
        getName: (type, path) => {
            if (Asset.path_name[type] && Asset.path_name[type][path])
                return Asset.path_name[type][path];
            return [];
        },
        getPath: (type, name) => {
            if (Asset.path_name[type]) {
                for (let path in Asset.path_name[type]) {
                    if (Asset.path_name[type][path].includes(name)) {
                        return path;
                    }
                }
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
            addZOrdering(this);
            enableEffects(this);
            aliasProps(this, this.graphics, ['x','y','visible','alpha','scale','skew','angle'])
            Scene.addDrawable(this.graphics);
            this.draw(...args);
        }
        _getPixiObjs () {
            return [this.graphics];
        }
        draw (...args) {
            let getTex = (name) => {
                let asset_path = Asset.getPath('image',name)
                return asset_path ? Asset.base_texture[asset_path] : name;
            }
            
            if (this.auto_clear)
                this.clear();

            let in_hole = false;
            for (let arg of args) {
                let skip_call = false; // not actually used yet
                let name = Draw.functions[arg[0]] || arg[0];
                let params = arg.slice(1);
                let extra_calls = [];

                if (name == 'beginFill' && params.length == 0) {
                    name = 'endFill';
                }
                if (name == 'beginTextureFill') {
                    if (params.length == 0)
                        name = "endFill";
                    else 
                        params[0] = getTex(params[0]);
                }
                if (name == 'lineTextureStyle') // width, line, ...
                    params[1] = getTex(params[1]);
                
                if (name == 'drawStar' && params.length >= 6)
                        params[5] = Util.rad(params[5])
                
                if (name == 'arc') {
                    if (params.length >= 4)
                        params[3] = Util.rad(params[3])
                    if (params.length >= 5)
                        params[4] = Util.rad(params[4])
                }

                if (name == 'beginHole' && in_hole) {
                    if (in_hole)
                        name = 'endHole';
                    in_hole = !in_hole;
                }

                if (name == 'entity' && params[0].sprite_index != '') {
                    name = 'beginTextureFill'
                    let ent = params[0];
                    let spr = ent.sprites[ent.sprite_index]
                    params[0] = spr.texture;
                    if (!params[1]) params[1] = Draw.white;
                    if (!params[2]) params[2] = 1;
                    if (!params[3]) params[3] = spr.matrix;
                    extra_calls = [
                        ['drawRect',spr.x - spr.pivot.x,spr.y - spr.pivot.y,spr.width,spr.height],
                        ['endFill']
                    ];
                }

                if (!skip_call && this.graphics[name])
                    this.graphics[name](...params);
                else
                    throw new Error(`${arg[0]} is not a Draw function`);
                if (extra_calls)
                    for (let call of extra_calls)
                        this.graphics[call[0]](...call.slice(1));
            }
        }
        clone () {
            let new_graphics = new Draw();
            replaceChild(new_graphics.graphics, this.graphics.clone());
            new_graphics.graphics = new_graphics;
            return 
        }
        containsPoint (x, y) {
            return this.graphics.containsPoint(new PIXI.Point(x,y));
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
        fill:       'beginFill',
        texture:    'beginTextureFill',
        bezier:     'bezierCurveTo',
        quadCurve:  'quadraticCurveTo',
        hole:       'beginHole',

        rect:       'drawRect',
        circle:     'drawCircle',
        polygon:    'drawPolygon',
        roundRect:  'drawRoundedRect',
        ellipse:    'drawEllipse',
        star:       'drawStar'
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

    /* -CANVAS */
    let empty_sprite;
    class Canvas { 
        constructor () {
            this.rtex = PIXI.RenderTexture.create(Game.width, Game.height);
            this.sprite = new PIXI.Sprite(this.rtex);
            this.width = Game.width;
            this.height = Game.height;
            this.auto_clear = true;
            addZOrdering(this);
            enableEffects(this);
            Scene.addDrawable(this.sprite);
            this._size_changed = false;
            window.addEventListener('resize',()=>{
                if (!this._size_changed && !this.options.ide_mode)
                    this.resize(app.view.width, app.view.height, true);
            })
            aliasProps(this, this.sprite, ['x','y','alpha','hitArea','scale']);
            enableEffects(this);
        }
        _getPixiObjs () { return [this.sprite]; }
        destroy () {
            this.sprite.destroy();
        }
        clear () {
            let old_auto_clear = this.auto_clear;
            this.auto_clear = true;
            this.draw(empty_sprite);
            this.auto_clear = old_auto_clear;
        }
        draw (obj, matrix) {
            if (obj._getPixiObjs) {
                obj = obj._getPixiObjs();
            }
            if (!Array.isArray(obj)) obj = [].concat(obj);
            for (let p in obj) {
                app.renderer.render(obj[p], this.rtex, this.auto_clear, matrix || null);
            }
            this.sprite.texture = this.rtex;
        }
        resize (w, h, internal) {
            this.width = w;
            this.height = h;
            this.rtex.resize(w, h);
            if (!internal)
                this._size_changed = true;
        }
    }

    /* -SCENE */
    class _Scene {
        constructor (name) {
            this.name = name;
            this.container = new PIXI.Container();
            this.container.filterArea = new PIXI.Rectangle(0,0,Game.width, Game.height);
            window.addEventListener('resize',()=>{
                if (this.container.filterArea) {
                    this.container.filterArea.width = Game.width;
                    this.container.filterArea.height = Game.height;
                }
            })
            this.objects = [];
            this.onStart = (scene) => {};
            this.onUpdate = (scene,dt) => {};
            this.onEnd = (scene) => {};
            game_container.addChild(this.container);
            enableEffects(this);
        }

        _getPixiObjs () {
            return [this.container];
        }

        destroy () {
            this.container.destroy();
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
            this.objects = [];
            this.container.visible = false;
            this.container.removeChildren();
        }
    
        update (dt) {
            this.onUpdate.call(this, dt);
            iter_scene_objects(this.objects, dt);
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

    Scene.switch = (name) => {
        // end other scenes
        for (let s_name in Scene.ref) {
            Scene.end(s_name);
        }
        // start it
        Scene.stack.push(name);
        Scene.ref[name]._onStart()
    }

    Scene.start = (name) => {
        if (!Scene.ref[name]) return;
        // if the scene is already running, end it
        if (Scene.ref[name].active)
            Scene.end(name);
        // start it
        Scene.stack.push(name);
        Scene.ref[name]._onStart();
    }
    
    Scene.end = (name) => {
        let index = Scene.stack.indexOf(name);
        if (index > -1 && Scene.ref[name]) {
            Scene.stack.splice(index,1);
            Scene.ref[name]._onEnd();
        }
    }
    
    Scene.endAll = () => {
        for (let name of Scene.stack) {
            Scene.end(name);
        }
    }

    // gets last added scene
    Scene.current = () => {
        if (Scene.stack.length > 0)
            return Scene(Scene.stack[Scene.stack.length-1]);
    }
    
    Scene.addDrawable = (pixi_obj) => {
        if (Scene.stack.length > 0) 
            Scene(Scene.stack[Scene.stack.length-1]).container.addChild(pixi_obj);
        else
            game_container.addChild(pixi_obj);
    }

    Scene.addUpdatable = (obj) => {
        let old_destroy = obj.destroy;
        obj.destroy = (...args) => {
            obj.destroyed = true;
            if (old_destroy) old_destroy.call(obj, ...args);
        }
        if (Scene.stack.length > 0) 
            Scene(Scene.stack[Scene.stack.length-1]).objects.push(obj);
        else 
            Scene.stray_objects.push(obj);    
    }

    let iter_scene_objects = (arr, dt) => {
        for (let o = arr.length - 1; o >= 0; o--) {
            let obj = arr[o];
            if (obj.destroyed)
                arr.splice(o, 1);
            else if (obj._update)
                obj._update(dt);
            else if (obj.update)
                obj.update(dt);
        }
    }

    // if a scene has not been createed
    Scene.stray_objects = [];
    app.ticker.add((dt) => {
        iter_scene_objects(Scene.stray_objects, dt);
    });
    
    Scene.ref = {};
    Scene.stack = [];

    /* -SPRITE */
    /* options = {
        offset: [0,0],
        columns: 1,
        frames: 1,
        frame_size: [0,0]
        spacing: [0,0]
        speed: 1    
    }
    */
    class Sprite {
        constructor (name, options) {
            this.animated = false;
            this._matrix = new Matrix(1,0,0,1,0,0);
            // animated sprite
            if ((options && options.frames) || (!options && name && name.frames)) {
                if (!options)
                    options = name;
                this.animated = true;
                let asset = Asset.texCrop(options.image || name, options)
                this.sprite = new PIXI.AnimatedSprite(asset.tex_frames);
                this.speed = options.speed;
                this.sprite.play();
            }
            // static image
            else if (typeof name == 'string') {
                let asset = Asset.get('image',name);
                this.sprite = new PIXI.Sprite(asset.texture);
            } else {
                this.sprite = new PIXI.Sprite();
            }
            if (!((options && options.no_scene) || (!options && name && name.no_scene)))
                Scene.addDrawable(this.sprite);

            this.sprite.x = 0;
            this.sprite.y = 0;
       
            let props = ['alpha','width','height','pivot','angle','scale','skew'];
        
            enableEffects(this);
            enableRect(this, () => this.sprite.getBounds(true));
            aliasProps(this, this.sprite, props);
        }
        _getPixiObjs () { return [this.sprite]; }
        get matrix () {
            this._matrix.setTransform(
                this.x, this.y, this.pivot.x, this.pivot.y, 
                this.scale.x, this.scale.y, this.angle, 
                this.skew.x, this.skew.y
            );
            return this._matrix;
        }
        get x () { return this.sprite.x; }
        set x (v){ this.sprite.x = v; }
        get y () { return this.sprite.y; }
        set y (v){ this.sprite.y = v; }
        get speed () { if (this.animated) return this.sprite.animationSpeed; }
        set speed (v){ if (this.animated) this.sprite.animationSpeed = v; }
        get frame () { return this.animated ? this.sprite.currentFrame : 0; }
        set frame (v) {
            if (!this.animated) return;
            if (this.speed == 0) this.sprite.gotoAndStop(v);
            else this.sprite.gotoAndPlay(v);
        }
        get frames () { return this.sprite.totalFrames; }
        get texture () { return this.sprite.texture }
        set texture (v) { this.sprite.texture = v }
        // resets all transforms
        reset () {
            this.sprite.setTransform();
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
        get align () { return this._align || ''; }
        set align (v) {
            this._align = v;
            if (v.includes('center')) 
                this.pivot.set(this.width/2 / this.scale.x,this.height/2 / this.scale.y);
            if (v.includes('left'))
                this.pivot.x = 0;
            if (v.includes('right'))
                this.pivot.x = this.width / this.scale.x;
            if (v.includes('top'))
                this.pivot.y = 0;
            if (v.includes('bottom'))
                this.pivot.y = this.height / this.scale.y;
        }
        destroy () {
            this.sprite.destroy();
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
            if (this.hash[obj._spatialhashlastkey]) {
                delete this.hash[obj._spatialhashlastkey][obj._spatialhashid];
                if (Object.values(this.hash[obj._spatialhashlastkey]).length == 0) 
                    delete this.hash[obj._spatialhashlastkey];
            }
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
                [opt.type == 'poly' ? 'polygon' : opt.type, ...opt.shape],
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
            if (this.destroyed) return;
            this.destroyed = true;
            Hitbox.world.remove(this);
            this.graphics.destroy();
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
            let spr_props = ['alpha','width','height','pivot','angle','scale','skew','frame','frames','align'];
            for (let p of spr_props) {
                Object.defineProperty(this,'sprite_'+p,{
                    get: function () {
                        if (this.sprites[this.sprite_index]) {
                            return this.sprites[this.sprite_index][p];
                        }
                        return 0;
                    },
                    set: function (v) {
                        for (let spr in this.sprites) {
                            this.sprites[this.sprite_index][p] = v;
                        }
                    }
                });
            }
            addZOrdering(this);
            enableEffects(this);
            if (this.init) this.init(...args);
            this.xprevious = this.x;
            this.yprevious = this.y;
            Scene.addUpdatable(this);
            storeInstance(Entity, this);
        }
        _getPixiObjs () {
            return Object.values(this.sprites).map(spr => spr.sprite);
        }
        destroy () {
            // destroy sprites
            for (let name in this.sprites) {
                this.sprites[name].destroy();
            }
            // destroy hitboxes
            for (let name in this.shapes) {
                this.shapes[name].destroy();
            }
            if (this._debug)
                this._debug.destroy();
        }
        get visible () { return this._visible || false; }
        set visible (v) { this._getPixiObjs().forEach(o => { o.visible = false }); }
        _update (dt) {
            if (this.destroyed) return;
            if (this.update)
                this.update(dt);
            if (this.destroyed) return;

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
                        this.onCollide[name].call(this, info[0], res);
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
        addSprite (name, opt) {
            this.sprites[name] = new Sprite(name, opt);
            if (this.sprite_index == '')
                this.sprite_index = name;
        }
        addShape (name, options) {
            if (typeof options == 'string') options = { type:options };
            options.tag = this.constructor.name + (options.tag ? '.'+options.tag : '');
            if (!options.shape) {
                switch (options.type) {
                    case 'rect': options.shape = [0,0,this.sprite_width,this.sprite_height]; break;
                    case 'circle': options.shape = [0,0,Math.max(this.sprite_width,this.sprite_height)/2]; break;
                }
            }
            // sprite pivot offset
            if (options.type == 'rect') { 
                options.shape[0] -= this.sprite_pivot.x;
                options.shape[1] -= this.sprite_pivot.y;
            }
            this.shapes[name] = new Hitbox(options);
            this.shapes[name].position(this.x, this.y);
            if (!this.shape_index)
                this.shape_index = name;
        }
        get debug () { return this._debug; }
        set debug (v) {
            if (v) {
                this._debug = new Draw();
            } else if (this._debug) {
                this._debug.destroy();
                this._debug = null;
                // disable hitbox debugs
                for (let name in this.shapes) {
                    this.shapes[name].debug = false;
                }
            }
        }
        updateDebug () {
            let d = this._debug;
            if (d) {
                // enable hitbox debugs
                for (let name in this.shapes) {
                    this.shapes[name].debug = true;
                }
                //
                d.x = this.x;
                d.y = this.y;
                d.draw(
                    ['lineStyle',1,Draw.green,0.75],
                    ['circle',0,0,4]
                )
            }  
        }
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
        set x (v) { this._x = v; this.updatePosition(); }
        set y (v) { this._y = v; this.updatePosition(); }
        updatePosition () {
            if (this.destroyed) return;
            for (let s in this.sprites) {
                this.sprites[s].x = this._x;// + this.sprites[s].pivot.x;
                this.sprites[s].y = this._y;// + this.sprites[s].pivot.y;
            }
            for (let name in this.shapes) {
                this.shapes[name].position(this._x, this._y);
            }
            this.updateDebug();
        }
        moveDirection (angle, speed) {
            this.hspeed = Util.direction_x(angle, speed);
            this.vspeed = Util.direction_y(angle, speed);
        }
    }

    /* -INPUT */
    let key_translation = {
        'down':'ArrowDown',
        'left':'ArrowLeft',
        'right':'ArrowRight',
        'up':'ArrowUp'
    };
    let input_ref = {};
    window.addEventListener('keyup',(e)=>{
        if (blanke_ref.focused) e.preventDefault();
        else return;
        Object.values(input_ref).forEach(obj => obj.release(e.key));
    });
    window.addEventListener('keydown',(e)=>{
        if (blanke_ref.focused) e.preventDefault();
        else return;
        Object.values(input_ref).forEach(obj => obj.press(e.key));
    });
    class _Input {
        constructor (name, inputs) {
            this.name = name;
            this.inputs = inputs.map(i => i.trim());
            this.options = {
                can_repeat: true
            }
            this.key_ref = {};              // { 'ArrowLeft' : ['left k'], 'k' : ['left k'] }
            this.press_count = {};          // { 'left k': 0 }
            this.combo_count = {};          // { 'left k': 2 }
            this.was_pressed = {};          // { 'left k': bool }
            this.release_checked = false;
            this.press_checked = false;
            this.pressed = false;
            this.released = false;

            for (let i of this.inputs) {
                i = i.trim();
                this.press_count[i] = 0;
                this.combo_count[i] = Util.str_count(i,' ')+1;
                this.was_pressed[i] = false;
                this.release_checked = false;
                this.press_checked = false;
                this.pressed = false;
                this.released = false;
                i.split(' ').forEach(n => {
                    n = key_translation[n] || n;
                    this.key_ref[n] = this.key_ref[n] || [];
                    this.key_ref[n].push(i);
                });
            }
        }
        update () {
            if (this.pressed && !this.options.can_repeat && !this.press_checked) {
                this.pressed = false;
                this.press_checked = true;
            }
            if (this.released && !this.release_checked) {
                this.released = false;
                this.release_checked = true;
            }
        }
        press (key) {
            let inputs = this.key_ref[key] || [];
            inputs.forEach(i => {
                if (this.press_count[i] < this.combo_count[i])
                    this.press_count[i] += 1;
                // all keys in this combo pressed
                if (this.press_count[i] >= this.combo_count[i] && (this.options.can_repeat || !this.was_pressed[i])) {
                    this.press_count[i] = this.combo_count[i];
                    this.was_pressed[i] = true;
                    this.press_checked = false;
                    this.pressed = true;
                }
            })
        }
        release (key) {
            let inputs = this.key_ref[key] || [];
            inputs.forEach(i => {
                if (this.press_count[i] > 0)
                    this.press_count[i] -= 1;
                if (this.press_count[i] < this.combo_count[i] && this.was_pressed[i]) {
                    this.was_pressed[i] = false;
                    this.release_checked = false;
                    this.released = true;

                    if (Object.values(this.was_pressed).every(v => !v)) {
                        this.pressed = false;
                    }
                }
            })
        }
        // returns { pressed: bool, released: bool }
        check () {
            return { 
                options: this.options,
                pressed: this.pressed, //Object.values(this.was_pressed).some(v => v), 
                released: this.released 
            }
        }
    }
    var Input = (...name) => {
        if (name.length == 1)
            return input_ref[name[0]] ? input_ref[name[0]].check() : {}
        else {
            let ret = { pressed: { any: false, all: true }, released: { any: false, all: true } };
            for (let n of name) {
                let val = input_ref[n] ? input_ref[n].check() : {}
                ret[n] = val;
                if (!val.pressed)
                    ret.pressed.all = false;
                else
                    ret.pressed.any = true;
                if (!val.released)
                    ret.released.all = false;
                else 
                    ret.released.any = true;
            }
            return ret;
        }
    }
    Input.set = (name, ...inputs) => {
        if (['set','inputCheck'].includes(name)) return;
        input_ref[name] = new _Input(name, inputs);


        if (!Input[name])
            Object.defineProperty(Input,name,{
                get: () => input_ref[name].options
            })
    };
    /*  Input.on('touch', (e) => {})    // defaults to whole canvas
        Input.on('touch', my_entity, (e) => {})
    */
    Input.stop_propagation = true;
    Input.on = (event, obj, cb) => {
        // user just wants click event in general (not a specific object)
        if (!cb) {
            cb = obj;
            obj = [app.stage];
            app.stage.hitArea = new PIXI.Rectangle(0,0,Game.width,Game.height);
        } else {
            // multiple objs given, flatten to pixi objects   
            if (Array.isArray(obj)) {
                obj = obj.reduce((a,c)=>{
                    if (c._getPixiObjs)
                        return a.concat(c._getPixiObjs());
                },[]);
            } else if (obj._getPixiObjs) {
                // single obj, convert to pixi object
                obj = obj._getPixiObjs();
            } else {
                return;
            }
        }
        // add the event for each Pixi object
        obj.forEach(o => { 
            o.interactive = true;
            o.input_parent = obj;
            o.on(event,(e)=>{
                let ret = true;
                if (Input.stop_propagation)
                    e.stopPropagation()
                if (cb) ret = cb(e, obj);
            });
        });
        return Input;
    }
    Input.update = () => {
       Object.values(input_ref).forEach(obj => obj.update() );
    }
    app.ticker.add(()=>{
        Input.update();
    },null,PIXI.UPDATE_PRIORITY.LOW);

    /* -VIEW 
    - at the moment, you can only have one view at a time.
    - alternatively use a Canvas and draw everything
    - difference between View and Canvas: View can capture input events and add specific objects to the 'view world'
    */
    let view_ref = {};
    class _View {
        constructor (name) { // keeping name property in case multiple views is more possible in the future
            this.name = name;
            this.container = new PIXI.Container();
            
            this.follow_obj = null;
            this.x = 0;
            this.y = 0;
            this.port_x = 0;
            this.port_y = 0;
            this.mask = new Draw();
            this._scale = new PIXI.Point(1,1);
            this.angle = 0;
            game_container.addChild(this.container);
            enableEffects(this);
        }
        _getPixiObjs () { return [this.container]; }
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
        get port_width () { return this._size_modified ? this._port_width : Game.width; }
        get port_height (){ return this._size_modified ? this._port_height : Game.height; }
        set port_width (v) {
            if (this._last_port_width != this._port_width)
                ;//cull.cull(this.getBounds()); 
            this._last_port_width = this._port_width;
            this._port_width = v; 
            this._size_modified = true;
        }
        set port_height (v) {
            if (this._last_port_height != this._port_height)
                ;//cull.cull(this.getBounds()); 
            this._last_port_height = this._port_height;
            this._port_height = v; 
            this._size_modified = true;
        }
        getBounds () {
            return {
                x: this._x, y: this._y,
                width: this._port_width, height: this._port_height
            }
        }
        get scale () {
            return this._scale;
        }
        follow (obj, dont_add_scene) {
            if (obj.view_follow && obj.view_follow.name == this.name)
                return;
            obj.view_follow = this;
            if (this.follow_obj) {
                this.follow_obj.view_follow = null;
                this.remove(this.follow_obj);
            }
            if (obj.x != null && obj.y != null) {
                this.follow_obj = obj;
                this.add(this.follow_obj)
            }
            let curr_scene = Scene.current();
            if (!dont_add_scene && curr_scene)
                this.add(curr_scene); 
        }
        add (...objects) {
            for (let obj of objects) {
                if (!obj.view || obj.view.name != this.name) {
                    obj.view = this;
                    setNewParent(obj, this.container);
                }
            }
            this.container.sortChildren();
        }
        remove (...objects) {
            for (let obj of objects) {
                obj.view = null;
                restorePrevParent(obj);
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
            this.container.pivot.x = -x;
            this.container.pivot.y = -y;
            this.container.x = this.port_x;
            this.container.y = this.port_y;
    
            this.x = x;
            this.y = y;
            
            this.mask.draw(
                ['fill',Draw.white],
                ['rect',
                    -x,
                    -y,
                    this.port_width,
                    this.port_height
                ],
                ['fill']
            );
            this.container.mask = this.mask.graphics;
        }
    }
    var View = (follow) => {
        let name = 'a_name';
        if (!view_ref[name])
            view_ref[name] = new _View(name);
        if (follow)
            view_ref[name].follow(follow);
        return view_ref[name];
    }
    View.names = () => Object.keys(view_ref);
    app.ticker.add(()=>{
        for (let name in view_ref) {
            view_ref[name].update();
        }
    },null,PIXI.UPDATE_PRIORITY.LOW+1);

    /* -MAP */
    class Map {
        constructor (name, from_file) {
            this.name = name;
            this.tile_hash = new SpatialHash();
            this.hitboxes = [];
            this.layers = []; // PIXI.Containers
            this.layer_uuid = {}; // layer_name --> layer_uuid
            this.main_container = new PIXI.Container();
            this.data = {};

            if (!from_file)
                this.addLayer('layer0');

            Scene.addDrawable(this.main_container);
            Scene.addUpdatable(this);
            this._debug = false;
            addZOrdering(this);
            enableEffects(this);
        }
        set x (v) { this.main_container.x = v }
        set y (v) { this.main_container.y = v }
        get x () { return this.main_container.x }
        get y () { return this.main_container.y }
        set debug (v) {
            this._debug = v;
            for (let hitbox of this.hitboxes) {
                hitbox.debug = v;
            }
        }
        get debug () { return this._debug; }
        _getPixiObjs () { return [this.main_container]; }
        static load (name) { 
            let data = Asset.get('map',name);
            if (!data) return;
            data = JSON.parse(data);
            let new_map = new Map(name, true);
            new_map.data = data;
            // ** ADD LAYERS **
            for (let lay_info of data.layers) {
                new_map.addLayer(lay_info.name, lay_info.uuid);
            }
            // ** PLACE TILES **
            for (let img_info of data.images) {
                // get layer image belongs to
                for (let lay_name in img_info.coords) {
                    let layer = new_map.getLayer(lay_name);
                    for (let c of img_info.coords[lay_name]) {
                        // place them
                        let asset_info = new_map.addTile(img_info.path, [c[0], c[1]], {
                            offset: [c[2], c[3]],
                            frame_size: [c[4], c[5]],
                            is_name: false
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

            // ** SET HITBOX COLORS ** 
            
            
            new_map.redrawTiles();
            return new_map;
        }
        addLayer (name, _uuid) {
            let new_cont = new PIXI.Container();
            new_cont._uuid = _uuid || uuid();
            new_cont._name = name;
            new_cont._graphics = new Draw();
            new_cont._graphics._getPixiObjs()[0].setParent(new_cont);
            this.main_container.addChild(new_cont);
            this.layers.push(new_cont);
            this.layer_uuid[name] = new_cont._uuid;
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
            if (opt.is_name) {
                // turn image name into path
                let name = Asset.getPath(name);
                if (!name) return;
            }
            if (opt.layer == null) opt.layer = this.layers[0]._name;
            // get the tile texture
            let asset = Asset.texCrop(name, opt);
            let tex_frames = asset.tex_frames;
            // place tiles
            for (let t = 0; t < pos.length; t += 2) {
                for (let f in tex_frames) {
                    this.tile_hash.add({
                        x: pos[t], y: pos[t+1],
                        w: tex_frames[f].width, h: tex_frames[f].height,
                        key: asset.key, frame: parseInt(f), img_name: name,
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
                tex = Asset.texCrop(tile.key, {is_key:true,from_asset:true});
                if (tex) {
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
            //return hit;
        }
        addEntity (entity_class, x, y, opt) {
            opt = Object.assign(Map._ent_default_opt, opt || {});
            let {layer, align, from_spawn, keep} = opt;
            let new_ent = new entity_class();
            new_ent.x = x;
            new_ent.y = y;
            // alignment
            if (align && from_spawn) {
                let obj_size = Game.config.scene.objects[from_spawn].size;
                // vertical align
                if (align.includes('bottom')) 
                    new_ent.y += (obj_size[1] / 2) - new_ent.sprite_height;
                
                if (align.includes('top')) 
                    new_ent.y -= (obj_size[1] / 2);
                
                // horizontal align
                if (align.includes('right')) 
                    new_ent.x += (obj_size[0] / 2) - new_ent.sprite_width;

                if (align.includes('left'))
                    new_ent.x -= (obj_size[0] / 2);
            }
            // add to layer
            if (keep) {
                let layer_obj = this.layers[0];
                if (layer) 
                    layer_obj = this.layers.find((l) => l._name == layer);
                etNewParent(new_ent, layer_obj);
            }
            return new_ent;
        }
        spawnEntity (entity_class, obj_name, opt) {
            opt = Object.assign(Map._ent_default_opt, opt || {});
            let {layer} = opt;
            let entities = [];
            if (!layer) {
                let layer_names = Object.keys(this.layer_uuid);
                for (let name of layer_names) {
                    opt.layer = name;
                    entities = entities.concat(this.spawnEntity(entity_class, obj_name, opt));
                }
                return entities;
            }
            let obj_uuid = Map.obj_uuid[obj_name];
            let layer_uuid = this.layer_uuid[layer];
            if (!obj_uuid || !layer_uuid) return;
            // spawn entity_class at every occurrence of obj_name
            for (let coords of this.data.objects[obj_uuid][layer_uuid]) {
                opt.from_spawn = obj_uuid;
                entities.push(this.addEntity(entity_class, coords[1], coords[2], opt));
            }
            return entities;
        }
    }
    Map.obj_uuid = {}; // obj_name --> obj_uuid from config.json
    Map.config = {};  // user-defined. used during Map.load()
    Map._ent_default_opt = {
        layer: null,
        align: null,
        from_spawn: null,
        keep: true
    }

    /* -AUDIO */
    let Audio = (name) => Asset.get('audio', name);
    Audio.play = (name) => {
        let asset = Asset.get("audio",name);
        if (asset) {
            asset.play();
        }
    }
    Audio.sprite = (name, sprites) => Asset.audioSprite(name, sprites);

    /* -TEXT */
    let f = Math.floor;
    class Text {
        constructor (str, opt) {
            if (typeof str == 'object') {
                opt = str;
                str = null;
            }
            this.options = Object.assign({
                fontFamily:'Arial',
                fontSize:12,
                align:"left",
                wordWrap:false,
                wordWrapWidth:100,
                breakWords:true
            },opt || {})
            this._updateOptions();

            this.x = 0;
            this.y = 0;
            this.iter = 0;
            this.max_height = 0;

            this.pixi_text = new PIXI.Text('', this.options);
            this.textures = []; // texture for each letter
            this.canvas = new Canvas();
            this.canvas.hitArea = new PIXI.Rectangle(0,0,0,0);
            this.canvas.auto_clear = false;
            this.temp_sprite = new Sprite({ no_scene: true });

            let props = []; //'alpha','anchor','angle','cursor'];
            //aliasProps(this, this.canvas, props);

            this.text = str || '';
            enableRect(this, ()=> this.canvas.hitArea);
            enableEffects(this);
            Scene.addUpdatable(this);
        }
        _getPixiObjs () { return this.canvas._getPixiObjs(); }
        destroy () {
            this.pixi_text.destroy();
            this.canvas.destroy();
            this.temp_sprite.destroy();
            if (this._debug) this._debug.destroy();
        }
        set debug (v) {
            if (!this._debug) 
                this._debug = new Draw();
        }
        get debug () { this._debug != null; }
        _updateOptions () {
            let keys = ['fontFamily','fontSize','align'];
            delete Text.textures[this.hash];
            this.hash = keys.map(k => this.options[k] || '').join("+");
            Text.textures[this.hash] = {};
        }
        set onDraw (v) { this.options.onDraw = v; }
        set text (v) { this._text = '' + v; }
        get text () { return this._text; }
        update (dt) {
            if (this.destroyed) return;
            this.canvas.clear();
            let x = 0, y = 0, o = this.options, str = this._text;
            let minx, miny, maxx, maxy;
            for (let l = 0; l < str.length; l++) {
                let letter = str.charAt(l);
                // get cached letter texture
                this.temp_sprite.reset();
                
                // TODO: is this optimal?
                if (Text.textures[this.hash][letter]) {
                    this.temp_sprite.texture = Text.textures[this.hash][letter];
                } else {
                    let pixi_text = new PIXI.Text(letter, this.options);
                    pixi_text.updateText();
                    this.temp_sprite.texture = pixi_text.texture;
                    Text.textures[this.hash][letter] = this.temp_sprite.texture.clone();
                }

                // allow user to change letter appearance  
                let props = {i:l, string:str, letter, x, y, sprite: this.temp_sprite, iter:this.iter};
                if (o.onDraw) {
                    o.onDraw(props);
                    this.iter++;
                }
                
                this.temp_sprite.x = this.x + props.x;
                this.temp_sprite.y = this.y + props.y;
                this.canvas.draw(this.temp_sprite);

                // set values for next letter
                x += this.temp_sprite.width;
                if (this.temp_sprite.height > this.max_height)
                    this.max_height = this.temp_sprite.height;
                if (o.wordWrap && x > o.wordWrapWidth && (o.breakWords || letter === ' ')) {
                    x = 0;
                    y += this.max_height;
                    this.max_height = 0;
                }

                // recalculate hitArea
                let bounds = this.temp_sprite.rect;
                if (minx == null) {
                    minx = bounds.x; miny = bounds.y;
                    maxx = bounds.x+bounds.width; maxy = bounds.y+bounds.height;
                }
                if (bounds.x < minx) minx = bounds.x;
                if (bounds.y < miny) miny = bounds.y;
                if (bounds.x + bounds.width > maxx) maxx = bounds.x + bounds.width;
                if (bounds.y + bounds.height > maxy) maxy = bounds.y + bounds.height;
            }
            // set hitArea
            let h = this.canvas.hitArea;
            h.x = f(minx);
            h.y = f(miny);
            h.width = f(maxx - minx);
            h.height = f(maxy - miny);
            // 
            if (this._debug) {
                this._debug.draw(
                    ['lineStyle',1,Draw.red],
                    ['rect',h.x,h.y,h.width,h.height]
                )
            }
        }
    }
    Text.textures = {};

    /* -EFFECT */
    class Effect {
        // Effect: (frag, vert), PIXI: (vert, frag) !!!!
        constructor (_name) {
            if (!Effect.library[_name]) 
                throw new Error(`Effect '${_name}' not found!`);
            let { name, frag, vert, defaults } = Effect.library[_name];

            this.name = name;
            this.filter = new PIXI.Filter(vert, frag, defaults);
            this.filter.name = name;
            let def_names = Object.keys(defaults);
            for (let def of def_names) {
                Object.defineProperty(this,def,{
                    get: function () { return this.filter.uniforms[def]; },
                    set: function (v){
                         this.filter.uniforms[def] = v; }
                })
            }
        }
        destroy () {
            this.filter.destroy();
        }
        static create (opt) {
            opt = Object.assign({
                name:'new_effect',
                defaults:{}
            }, opt || {})
            Effect.library[opt.name] = opt;
        }
    }
    Effect.library = {};
    class EffectManager {
        constructor (parent) {
            this.effects = {};
            this.parent = parent;
        }
        add (name) {
            if (!this.effects[name]) {
                // add to parent
                this.effects[name] = new Effect(name)
                this.updateParentFilters();
            }
        }
        updateParentFilters () {
            this.parent._getPixiObjs().forEach((obj)=>{
                obj.filters = Object.values(this.effects).map(e => e.filter);
            });
        }
        remove (name) {
            if (this.effects[name]) {
                // remove from parent
                this.effects[name].destroy();
                delete this.effects[name];
                this.updateParentFilters();
            }
        }
    }

    /* -MATRIX */
    let Matrix = PIXI.Matrix;

    /* -RECTANGLE */
    let Rectangle = PIXI.Rectangle;

    /* -TIMER */
    let Timer = {
        fn_after: [],
        fn_every: [],
        after: (t, fn) => { Timer.fn_after.push({ t:t, 
            start_t:Game.ms, 
            end_t:Game.ms+t, 
            fn:fn || function(){},
             
        }); return Timer.fn_after[Timer.fn_after.length-1]; },
        every: (t, fn) => { Timer.fn_every.push({ t:t, 
            last_t:Game.ms, 
            curr_t:0, 
            iter:0, 
            fn:fn || function(){},
        }); return Timer.fn_every[Timer.fn_every.length-1]; }
    }
    app.ticker.add((dt)=>{
        let ms = Game.ms;
        // after
        for (let f = Timer.fn_after.length - 1; f >= 0; f--) {
            let info = Timer.fn_after[f];
            if (!info.done && ms >= info.end_t) {
                info.fn();
                // remove timer
                Timer.fn_after.splice(f, 1);
            }
        }
        // every
        for (let f = Timer.fn_every.length - 1; f >= 0; f--) {
            let info = Timer.fn_every[f];
            if (!info.done && info.curr_t > info.t) {
                info.last_t = ms;
                info.iter++;
                // remove the timer if user returns true
                if (info.fn(info.iter) == true) 
                    Timer.fn_every.splice(f, 1);
            }
            info.curr_t = ms - info.last_t;
        }
    });

    engineLoaded.call(this);
    var classes = {Asset, Audio, Canvas, Draw, Effect, Entity, Game, Hitbox, Input, Map, Matrix, Rectangle, Scene, Sprite, Text, Timer, Util, View};
    return classes;
}
Blanke.addGame = (name, options) => {
    if (!Blanke.game_options) Blanke.game_options = {};
    Blanke.game_options[name] = options;
}
Blanke.run = (selector, name) => {
    if (!Blanke.game_options) Blanke.game_options = {};
    if (Blanke.game_options[name])
        Blanke(selector, Blanke.game_options[name])
    else
        console.log(`BlankE game '${name}' not found!`);
}
