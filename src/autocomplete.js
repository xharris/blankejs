let color_vars = {
	r:'red component (0-1 or 0-255) / hex (#ffffff) / preset (\'blue\')',
	g:'green component',
	b:'blue component',
	a:'optional alpha'
}
let color_prop = '{r,g,b} (0-1 or 0-255) / hex (\'#ffffff\') / preset (\'blue\')';

module.exports.keywords = ['local']

// only vars starting with 'local'
module.exports.user_words = {
	'var':[
		/(?:(?:local\s+)(?!\.)([a-zA-Z_]\w*),?\s*)[^\n\r\.\:]+?(?!=\s*function)(?==)/g
	],
	'fn':[
		/(?:local\s+)(?!\.)([a-zA-Z_]\w*)\s*=\s*function\s*\(/g,
		/function\s+(?!\.)([a-zA-Z_]\w*)\s*\(/g
	]
}

module.exports.class_list = ['Net','Group','Canvas','Draw','BlankE','Asset','Input','Image','Scene','Bezier','Window','math'];

// Group 1: name of class to replace <class_name> in instance_regex
module.exports.class_regex = {
	'state': 	[
		/.*BlankE\.addClassType\s*\(\s*"(\w+)"\s*,\s*"State"\s*\).*/g,
		/.*BlankE\.addState\s*\(\s*"(\w+)"\s*\).*/g,
		/\b(State).*/g
	],
	'entity': 	[
		/.*BlankE\.addClassType\s*\(\s*"(\w+)"\s*,\s*"Entity"\s*\).*/g,
		/.*BlankE\.addEntity\s*\(\s*"(\w+)"\s*\).*/g
	]
}

// Group 1: name of instance 
module.exports.instance_regex = {
	'entity': 	[
		/\b(\w+)\s*=\s*<class_name>\(\).*/g,
		/\b(\w+)\s*=\s*<class_name>\.instances\[\d+\].*/g,
		/\b(\w+)\s*=\s*<class_name>\.instances:get\(\d+\).*/g
	],
	'input': 	/\b(Input\([\'\"]\w+[\'\"]\))/g,
	'image': 	/\b(\w+)\s*=\s*Image\([\'\"].+[\'\"]\)\s+?/g,
	'scene': 	/\b(\w+)\s*=\s*Scene\([\'\"]?[\w\.]+[\'\"]?\)\s+?/g,
	'audio': 	/\b(\w+)\s*=\s*Audio\([\'\"][\w\.\s]+[\'\"]\)\s+?/g,
	'view': 	/\b(\w+)\s*=\s*View\([\w\.\s]*\)\s+?/g,
	'repeater':	/\b(\w+)\s*=\s*Repeater\([\w\.\s\,\{\}\=]*\)?\s?/g,
	'group': 	[
		/\b(?:self\.)?(\w+)\s*=\s*Group\(\)\s+?/g,
		/\b(\w+\.instances).*/g
	],
	'bezier': 	/\b(\w+)\s*=\s*Bezier\([\d.,]*\)\s+?/g,
	'timer': 	/\b(\w+)\s*=\s*Timer\(\d*\)\s+?/g,
	'canvas': 	/\b(\w+)\s*=\s*Canvas\((?:\d*\,\d*)?\)\s+?/g
}
// old group/bezier regex: /\b(?:self.|self:)?(\w+)\s*=\s*Group\(\).*/g

// how to treat use of the 'self' keyword when used inside a callback
module.exports.self_reference = {
	'blanke-state': 'class',
	'blanke-entity': 'instance'
}

module.exports.completions = {
	"global":[
		{fn:"Image", vars:{ name:'images/ground.png -> Image(\"ground\")' }},
		{prop:"game_width"}
	],
	"blanke-blanke":[
		{fn:"init", vars:{ first_state:'State the game should start in' }},
		{fn:"addClassType",
		vars:{
			object_name:'MenuState / Player / ...', object_type:'State / Entity / etc.'
		}},
		{fn:"addState", vars:{ object_name:'MenuState / PlayState / ...' }},
		{fn:"addEntity", vars:{ object_name:'Player / Powerup / ...' }},
		{fn:"loadPlugin", vars:{ name:'' }},
		{prop:"draw_debug"}
	],
	"blanke-math":[
		{fn:'min',vars:{etc:''}},
		{fn:'max',vars:{etc:''}},

		{fn:'sqrt',vars:{n:'must be positive'}},
		{fn:'abs',vars:{n:''}},
		{fn:'ceil',vars:{n:''}},
		{fn:'floor',vars:{n:''}},
		{fn:'deg',vars:{radians:''}},
		{fn:'rad',vars:{degrees:''}},
		{fn:'pi'},

		{fn:'sin',vars:{n:''},info:'returns radians'},
		{fn:'cos',vars:{n:''},info:'returns radians'},
		{fn:'tan',vars:{n:''},info:'returns radians'},
		{fn:'acos',vars:{n:''},info:'returns radians'},
		{fn:'asin',vars:{n:''},info:'returns radians'},
		{fn:'atan',vars:{y:'',x:'optional'},info:'returns radians'},

		{fn:'exp',vars:{n:''},info:'e^n (natural log)'},
		{fn:'log',vars:{n:''},info:'inverse of math.exp'},
		{fn:'modf',vars:{n:''},info:'splits a decimal, Ex. -5.3 -> -5, -0.3'},
		{fn:'huge',info:'+infinity'},
		{fn:'maxinteger'},
		{fn:'mininteger'},
		{fn:'modf'},
		{fn:'tointeger'},
		{fn:'type',vars:{n:''},info:"whether n is \'integer\',\'float\',nil (NaN)"},
		{fn:'sign',vars:{n:''},info:"returns -1 or 1 depending on sign of n"},
		{fn:'ult',vars:{m:'',n:''},info:"true IF abs(m) < abs(n) ELSE false"}
	],
	"blanke-net":[
		{prop:"id", info:"unique clientid assigned upon connecting to a network"},
		{prop:"is_leader", info:"check this value if you only want to run a Net action once on a server"},
		{fn:"join", vars:{ address:"localhost", port:"8080" }},
		{fn:"disconnect"},
		{fn:"send", vars:{ data:"{type (netevent), event, info}" }},
        {fn:"event", vars:{ name:"", data:"" }},
        {fn:"sendPersistent", vars:{ data:'' }, info:"same as send, but sends to new clients that join later"},
		{fn:"getPopulation"},
		{fn:"getObjects", vars:{ classname:"optional", clientid:"optional" }},
		{fn:"draw", vars:{ classname:"optional" }},
		{fn:"addObject", vars:{ obj:'best used with Entity and other objects' }},
		{fn:"on", vars:{ callback:'ready / connect(id) / disconnect(id) / receieve(data) / event(data)', fn:'' }}
	],
	"blanke-group-instance":[
		{fn:"add", vars:{ obj:'' }},
		{fn:"get", vars:{ index:'' }},
		{fn:"remove", vars:{ index:'number / reference to object with a uuid' }},
		{fn:"clear", vars:{ clear:'' }},
		{fn:"forEach", vars:{ func: 'calls func(index, obj) for each object'}},
		{fn:"call", vars:{ func_name:'calls object[func_name](...) for each object', etc:'' }},
		{fn:"destroy"},
		{fn:"closest_point", info:'Entity only. get Entity closest to point', vars:{ x:'', y:'' }},
		{fn:"closest", info:'Entity only. get Entity closest to entity', vars:{ entity:'' }},
		{fn:"size", info:'number of children'},
		{fn:"sort", vars:{ attribute:'', descending:'default: false' }},
		{fn:"find", vars:{ key:'', val:'' }, info:'given : what happens</br>key : return index of v where v == key</br>key, val : return (element, index) where group[index][key] == val'}
	],
	"blanke-bezier-instance":[
		{fn:"addPoint", vars:{ x:'', y:'', i:'optional index. -1 = last' }},
		{fn:"removePoint", vars:{ i:'' }},
		{fn:"getPoint", vars:{ i:'' }},
		{fn:"pointCount"},
		{fn:"clear"},
		{fn:"at", vars:{ t:'' }},
		{fn:"draw"},
		{fn:"drawPoints"}
	],
	"blanke-asset":[
		{fn:"add", vars:{ path:'file or folder (ending with \'/\')' }},
		{fn:"list", vars:{ file_type:'script / image / map / file' }}
	],
	"blanke-draw":[
		{fn:"translate", vars:{ x:'', y:'' }},
		{fn:"scale", vars:{ x:'', y:'' }},
		{fn:"shear", vars:{ x:'', y:'' }},
		{fn:"rotate", vars:{ degrees:'' }},
		{fn:"crop", vars:{ x:'', y:'', width:'', height:'' }},
		{fn:"setBackgroundColor", vars:color_vars, info:'[!!] use <StateName>.background_color instead'},
		{fn:"randomColor", vars:{ alpha:'' }},
		{fn:"setColor", vars:color_vars},
		{prop:"colors", info:'list of available colors'},
		{fn:"setLineWidth", vars:{ width:'' }},
		{fn:"point", vars:{ x:'', y:'' }},
		{fn:"points"},
		{fn:"line", vars:{ x1:'', y1:'', x2:'', y2:'' }},
		{fn:"rect", vars:{ mode:'fill / line', x:'', y:'', width:'', height:''}},
		{fn:"circle", vars:{ mode:'fill / line', x:'', y:'', radius:''}},
		{fn:"polygon"},
		{fn:"text", vars:{ text:'', x:'', y:'', etc:'' }},
		{fn:"textf"},
		{fn:"reset", vars:{ specific:'(optional) color, crop, transform' }},
		{fn:"stack", vars:{ fn:'' }, info:"resets all draw operations after fn. push -> fn -> pop"},
		{prop:'red'},{prop:'pink'},{prop:'purple'},{prop:'indigo'},{prop:'baby_blue'},{prop:'blue'},{prop:'dark_blue'},{prop:'green'},
		{prop:'yellow'},{prop:'orange'},{prop:'brown'},{prop:'gray'},{prop:'grey'},{prop:'black'},{prop:'white'},{prop:'black2'},
		{prop:'white2'},
	],
	"blanke-input":[
		{fn:"set", vars:{ label:'', input1:'input to catch</br>- mouse: mouse.1, mouse.2, ...</br>- letters: w, a, s, d, ...', etc:'' }}
	],
	"blanke-input-instance":[
		{prop: "can_repeat"},
		{fn: "reset"}
	],
	"blanke-state":[
		{fn:"switch",
		vars:{
			name: "name of state to switch to"
		}},
		{fn:"transition"},
		{prop:"in_transition",info:"read-only"},
		{fn:"current"},
		{fn:"enter", callback: true,
		vars:{
			prev_state: "state that was active before this one"
		}},
		{fn:"update", callback: true},
		{fn:"draw", callback: true},
		{fn:"leave", callback: true},
		{prop:"background_color"}
	],
	"blanke-entity":[
		{fn:"init", callback: true},
		{fn:"preUpdate", callback: true, vars:{ dt:'' }},
		{fn:"update", callback: true, vars:{ dt:'' }},
		{fn:"preDraw", callback: true},
		{fn:"draw", callback: true},
		{fn:"postDraw", callback: true}
	],
	"blanke-entity-instance":[
		{prop:"x"},
		{prop:"y"},
		{prop:"direction", info:"best used with 'speed'"},
		{prop:"friction"},
		{prop:"gravity"},
		{prop:"gravity_direction", info:"in degrees. 0 = right, 90 = down, default = 90"},
		{prop:"hspeed"},
		{prop:"vspeed"},
		{prop:"speed", info:"best used with 'direction'"},
		{prop:"angle", info:"changes angle of hitboxes"},
		{prop:"xprevious"},
		{prop:"yprevious"},
		{prop:"xstart"},
		{prop:"ystart"},

		{prop:"sprite_index"},
		{prop:"sprite_angle"},
		{prop:"sprite_xscale"},
		{prop:"sprite_yscale"},
		{prop:"sprite_xoffset"},
		{prop:"sprite_yoffset"},
		{prop:"sprite_xshear"},
		{prop:"sprite_yshear"},
		{prop:"sprite_color"},
		{prop:"sprite_alpha"},
		{prop:"sprite_speed"},
		{prop:"sprite_frame"},
		{prop:"sprite_width"},
		{prop:"sprite_height"},

		{prop:"show_debug", info:"debugSprite() and debugCollision() are automatically called"},

		{fn:"addAnimation",named_args:true,vars:{
			name:'', 
			image:'name of asset (ex. bob_stand, bob_walk)', 
			frames:'{\'1-2\', 1} means columns 1-2 and row 1', 
			frame_size:'{32,32} means each frame is 32 by 32', 
			speed:'0.1 smaller = faster'
		}},
		{fn:"addShape", vars:{
			name:'',
			shape:'rectangle / polygon / circle / point',
			shape_size: '{left,top,width,height} / {x1,y1,x2,y2,...} / {x,y,radius} / {x,y}',
			tag:'optional'
		}},
		{fn:"drawSprite",vars:{ name:'calls default draw function for given animation name' }},

		{fn:"distance", vars:{ other:"Entity" }},
		{fn:"distancePoint", vars:{ x:'', y:'' }, info:'entity origin distance from point'},
		{fn:"moveTowardsPoint", vars:{ x:'', y:'', speed:'' }},
		{fn:"containsPoint", vars:{ x:'', y:'' }, info:'checks if a point is inside the sprite (not hitboxes)'},

		{fn:"destroy"},

		{fn:"hadCollision",vars:{shape_name:'', other_tag:''}},
		{fn:"getCollisions",vars:{shape_name:''}},
		{fn:"debugSprite",vars:{sprite_index:''}},
		{fn:"debugCollision"}
	],
	"blanke-image-instance":[
		{prop:"x"},
		{prop:"y"},
		{prop:"angle"},
		{prop:"xscale"},
		{prop:"yscale"},
		{prop:"xoffset"},
		{prop:"yoffset"},
		{prop:"alpha"},
		{prop:"orig_width", info:"read-only"},
		{prop:"orig_height", info:"read-only"},
		{prop:"width"},
		{prop:"height"},
		{fn:"draw",vars:{x:"opt. override",y:"opt. override"}},
		{fn:"crop",vars:{x:"",y:"",width:"",height:""}},
		{fn:"chop",vars:{piece_w:"",piece_h:""},info:"returns Group containing parts of the Image"},
		{fn:"combine",vars:{other_image:""},info:"combines another image into this one"},
		{fn:"setWidth",vars:{w:""}},
		{fn:"setHeight",vars:{h:""}},
		{fn:"setSize",vars:{w:"",h:""}},
		{fn:"setScale",vars:{x:"",y:"optional"}},
		{fn:"tileX",vars:{w:""}},
		{fn:"tileY",vars:{h:""}},
		{fn:"tile",vars:{w:"",h:""}}
	],
	"blanke-audio-instance":[
		{prop:"pitch"},
		{prop:"volume"},
		{prop:"x",info:"position"},
		{prop:"y",info:"position"},
		{prop:"z",info:"position"},
		{prop:"looping"},
		{prop:"seconds",info:"currently playing position"},
		{fn:"play"},
		{fn:"pause"},
		{fn:"stop"},
		{fn:"playAll",info:"play all Audio that use the same asset"},
		{fn:"stopAll",info:"pause all Audio that use the same asset"},
		{fn:"pauseAll",info:"stop all Audio that use the same asset"}
	],
	"blanke-scene":[
		{prop:"tile_hitboxes"},
		{prop:"hitboxes"},
		{prop:"entities"},
		{prop:"dont_draw"},
		{prop:"draw_order"}
	],
	"blanke-scene-instance":[
		{prop:"angle",info:"rotate all tiles and hitboxes (not entities)"},
		{prop:"center_x",info:"center used when rotating with .angle"},
		{prop:"center_y",info:"center used when rotating with .angle"},
		{prop:"draw_hitboxes"},
		{fn:"addHitbox",vars:{ object_name:"", etc:"" }},
		{fn:"addTileHitbox",vars:{ image_name:"", etc:"" }},
		{fn:"addEntity",vars:{ object_name:"", entity_class:"", alignment:"center, left, right, top, bottom, top-left, center-bottom, etc." }},
		{fn:"getEntities",vars:{ object_name:"" }},
		{fn:"chain",vars:{ next_scene:"Scene object", end_object:"ending object of previous scene", start_object:"starting object of next scene"}},
		{fn:"translate",vars:{ x:"", y:"" }},
		{fn:"draw"}
	],
	"blanke-timer-instance":[
		{prop:"time", info:"seconds elapsed"},
		{prop:"duration", info:"timer duration (sec)"},
		{prop:"countdown", info:"read-only version of [time] except counts backwards"},
		{fn:"start"},
		{fn:"before", vars:{ func:'', delay:'optional' }},
		{fn:"every", vars:{ func:'', delay:'optional' }},
		{fn:"after", vars:{ func:'', delay:'optional' }},
		{fn:"reset"}
	],
	"blanke-view-instance":[
		{prop:"angle"},
		{prop:"scale_x"},
		{prop:"scale_y"},
		{prop:"port_width"},
		{prop:"port_height"},
		{prop:"zoom"},
		{fn:"shake",vars:{x:"",y:"optional"}},
		{prop:"shake_speed"},
		{prop:"shake_duration",info:"seconds"},
		{prop:"top",info:"read only"},
		{prop:"bottom",info:"read only"},
		{prop:"left",info:"read only"},
		{prop:"right",info:"read only"},
		{fn:"follow",vars:{ entity_instance:'' }},
		{fn:"draw",vars:{ draw_fn:'' }}
	],
	"blanke-repeater-instance":[
		{prop:"lifetime"},
		{prop:"duration"},
		{prop:"rate"},
		{prop:"spawn_x"},
		{prop:"spawn_y"},
		{prop:"start_color",info:color_prop},
		{prop:"end_color",info:color_prop},
		{prop:"linear_accel_x"},
		{prop:"linear_accel_y"},
		{prop:"linear_damp_x"},
		{prop:"linear_damp_y"},
		{fn:"draw"},
		{fn:"setTexture",vars:{'texture':'entity_instance, image, canvas'}}
	],
	"blanke-window":[
		{prop:"aspect_ratio", info:"table. default: {4,3}"},
		{prop:"scale_mode", info:"scale, stretch, fit, center"},
		{fn:"getResolution"},
		{fn:"setResolution", vars:{ w:'', h:'' }, info:"uses predefined ratio if only 'w' is given"},
		{fn:"setFullscreen", vars:{ value:'true = on, false = off' }},
		{fn:"getFullscreen", info:"returns true if game is in fullscreen"},
		{fn:"toggleFullscreen"}
	],
	"blanke-canvas-instance":[
		{prop:"width"},
		{prop:"height"},
		{fn:"drawTo", vars:{ draw_fn:'' }},
		{fn:"draw"},
		{fn:"resize", vars:{ w:'', h:'' }}
	]
}