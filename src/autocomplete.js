let color_vars = {
	r:'red component (0-1 or 0-255) / hex (#ffffff) / string (\'blue\')',
	g:'green component',
	b:'blue component',
	a:'optional alpha'
}

module.exports.class_list = ['Net','Group','Draw','BlankE','Asset','Input','Image','Scene','Bezier'];

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
	'entity': 	/\b(\w+)\s*=\s*<class_name>\(\).*/g,
	//'input': 	/\bInput\.keys(\[[\'\"]\w+[\'\"]\])/g,
	'image': 	/\b(\w+)\s*=\s*Image\([\'\"][\w\.]+[\'\"]\)\s+?/g,
	'scene': 	/\b(\w+)\s*=\s*Scene\([\'\"][\w\.]+[\'\"]\)\s+?/g,
	'group': 	/\b((?:self.|self:)?\w+)\s*=\s*Group\(\).*/g,
	'bezier': 	/\b((?:self.|self:)?\w+)\s*=\s*Bezier\([\d.,]*\).*/g
}

// how to treat use of the 'self' keyword when used inside a callback
module.exports.self_reference = {
	'blanke-state': 'class',
	'blanke-entity': 'instance'
}

module.exports.completions = {
	"global":[
		{fn:"Image", vars:{ name:'images/ground.png -> Image(\"ground\")' }}
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
	"blanke-net":[
		{prop:"id", info:"clientid assigned on connecting to a network"},
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
		{fn:"forEach", vars:{ func: 'calls func(index, obj) for each object'}},
		{fn:"call", vars:{ func_name:'calls object[func_name](...) for each object', etc:'' }},
		{fn:"destroy"},
		{fn:"closest_point", info:'Entity only. get Entity closest to point', vars:{ x:'', y:'' }},
		{fn:"closest", info:'Entity only. get Entity closest to entity'},
		{fn:"size", info:'number of children'}
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
		{prop:"colors", info:'list of available colors'},
		{fn:"setBackgroundColor", vars:color_vars},
		{fn:"randomColor", vars:{ alpha:'' }},
		{fn:"setColor", vars:color_vars},
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
		{fn:"stack", vars:{ fn:'' }, info:"resets all draw operations after fn. push -> fn -> pop"}
	],
	"blanke-input":[
		{fn:"set", vars:{ label:'', input1:'input to catch</br>- letters: w, a, s, d, ...', etc:'' }}
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
		{prop:"direction"},
		{prop:"friction"},
		{prop:"gravity"},
		{prop:"gravity_direction", info:"in degrees. 0 = right, 90 = down, default = 90"},
		{prop:"hspeed"},
		{prop:"vspeed"},
		{prop:"speed", info:"best used with 'direction'"},
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
		{fn:"drawSprite",vars:{ name:'calls default draw function for given animation name' }},

		{fn:"distancePoint", vars:{ x:'', y:'' }, info:'entity origin distance from point'},
		{fn:"moveTowardsPoint", vars:{ x:'', y:'', speed:'' }},
		{fn:"containsPoint", vars:{ x:'', y:'' }, info:'checks if a point is inside the sprite (not hitboxes)'},

		{fn:"destroy"},

		{fn:"hadCollision",vars:{self_name:'', other_name:''}},
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
		{fn:"draw"},
		{fn:"crop",vars:{x:"",y:"",width:"",height:""}}
	],
	"blanke-scene-instance":[
		{prop:"draw_hitboxes"},
		{fn:"addHitbox",vars:{ object_name:"", etc:"" }},
		{fn:"addTileHitbox",vars:{ image_name:"", etc:"" }},
		{fn:"addEntity",vars:{ object_name:"", entity_class:"", alignment:"center, left, right, top, bottom, top-left, center-bottom, etc." }},
		{fn:"getEntities",vars:{ object_name:"" }},
		{fn:"chain",vars:{ next_scene:"Scene object", end_object:"ending object of previous scene", start_object:"starting object of next scene"}},
		{fn:"translate",vars:{ x:"", y:"" }},
		{fn:"draw"}
	]
}