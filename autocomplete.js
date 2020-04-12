
let color_vars = {
	r:'red component (0-1 or 0-255) / hex (#ffffff) / preset (\'blue\')',
	g:'green component',
	b:'blue component',
	a:'optional alpha'
}
let color_prop = '{r,g,b} (0-1 or 0-255) / hex (\'#ffffff\') / preset (\'blue\')';

let prop_z = { prop: 'z', info: 'lower numbers are drawn behind higher numbers' }
let prop_xy = [
	{ prop: 'x' },
	{ prop: 'y' }
]
let prop_xyz = [
	...prop_xy,
	prop_z
]
let prop_pixi_point = (name) => ({ prop: name || 'point', info: '{ x, y, set(x, y=x) }' })
let prop_gameobject = [
	...prop_xyz,
	...(['angle','scalex','scaley','scale','width','height','offx','offy','shearx','sheary'].map(p => ({ prop:p }))),
	{ prop: 'align', info: 'left/right top/bottom center'},
	{ prop: 'blendmode', info: '{ mode, alphamode }'},
	{ prop: 'uuid' },
	{ fn: 'setEffect', vars: { name:'...' } },
	{ prop: 'effect' },
	{ fn: 'destroy' }
]

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#Keywords
// used Array.from(document.querySelectorAll("#Reserved_keywords_as_of_ECMAScript_2015 + .threecolumns code")).map((v)=>"'"+v.innerHTML+"'").join(',')
module.exports.keywords = ['true','false']/*
	'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 
	'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 
	'until', 'while'
]*/

// TestScene is included just so it looks nice
module.exports.class_list = [
	"Math", "FS", "Game", "Canvas", "Image", "Entity",
	"Input", "Draw", "Color", "Audio", "Effect", "Camera",
	"Map", "Physics", "Hitbox", "State", "Timer", "Window", 
	"Net", "Blanke", "class", "table"
];

module.exports.class_extends = {
	'entity': /\bEntity\s*\(\s*[\'\"](\w+)[\'\"],\s*/g,
	'class': /\b(\w+)\s*=\s*class\s*\{/g
}

module.exports.instance = {
	'entity': /\b(\w+)\s*=\s*Game\.spawn\(\s*[\'\"]<class_name>[\'\"]\s*\)/g,
	'map': /\b(\w+)\s*=\s*Map\.load\([\'\"].+[\'\"]\)/g,
	'canvas': /(@?\w+)\s*(?::|=)\s*Canvas[\s\(]/g
}

module.exports.user_words = {/*
	'var':[
		// single var
		/([a-zA-Z_]\w+?)\s*=\s(?!function|\(\)\s*[-|=]>)/g,
		/(?:local)\s+([a-zA-Z_]\w+)/g,
		/(@?[a-zA-Z_]\w+)/g,
		// comma separated var list
		/(?:let|var)\s+(?:[a-zA-Z_]+[\w\s=]+?,\s*)+([a-zA-Z_]\w+)(?!\s*=)/g
	],
	'fn':[
		// var = function
		/([a-zA-Z_]\w+?)\s*=\s(?:function|\(\)\s*[-|=]>)/g,
		// function var()
		/function\s+([a-zA-Z_]\w+)\s*\(/g
	]*/
}

module.exports.image = [
	/Image\.animation\s*\(\s*['"]([\w\s\/.-]+)['"]\s*(?:,[\s\{]*(['"\w\s\/.\-=\s,{}]+)\s*})?\s*\)/g
];

module.exports.entity_using_image = [
	/Entity\s*\(\s*[\'\"](\w+)[\'\"],.*[\s,{]animation[\s=]+['"]([\w\s\/.-]+)['"]/g,
	/Entity\s*\(\s*[\'\"](\w+)[\'\"],.*[\s,{]image[\s=]+['"]([\w\s\/.-]+)['"]/g,
	/Entity\s*\(\s*[\'\"](\w+)[\'\"],.*[\s,{]animations[\s=]+\{\s*['"]([\w\s\/.-]+)['"]/g,
	/Entity\s*\(\s*[\'\"](\w+)[\'\"],.*[\s,{]images[\s=]+\{\s*['"]([\w\s\/.-]+)['"]/g,
];

module.exports.sprite_align = [
	/Entity\s*\(\s*[\'\"](\w+)[\'\"],.*align[\s=]+['"]([\w\s\/.-]+)['"]/g
]

module.exports.this_ref = {
	'blanke-entity-instance':/\bEntity\s*\(\s*[\'\"](\w+)[\'\"],\s*/g
}

module.exports.this_keyword = 'self';

/*
	{ fn: "name", info, vars }
	{ prop: "name", info }

	- info: "description"
	- vars: { arg1: 'default', arg2: 'description', etc: '' }
*/
module.exports.hints = {
	"global":[
		{fn: "Draw", vars: { args:'...' } },
		{fn:'switch', vars:{v:'',choices_t:'{ choice1 = function() end, ... }'}},
		{fn:'copy', vars:{t:''}, info:'returns deepcopy of table'},
		{fn:'is_object', vars:{v:''}, info:'is v an instance of a class'},
		{fn:'encrypt', vars:{str:'',code:'hashing key',seed:'opt number'}},
		{fn:'decrypt', vars:{hashed_str:'',code:'hashing key used to encrypt',seed:'opt number used to encrypt'}}
	],
	"blanke-table":[
		{fn:'update', vars: { old:'', 'new':'', keys:'opt' } },
		{fn:'keys', vars: { t:'' }},
		{fn:'every', vars:{t:''}},
		{fn:'some', vars:{t:''}},
		{fn:'len', vars:{t:''}},
		{fn:'hasValue', vars:{t:'',val:''}},
		{fn:'slice', vars:{t:'',start:'opt 1',end:'opt #t'}, info:'returns segment of table'},
		{fn:'defaults', vars:{t:'',defaults_t:''}},
		{fn:'append', vars:{t:'',new_t:''}},
		{fn:'filter', vars:{t:'',fn:'(item, index) => true to keep value, false to remove'}},
		{fn:'random', vars:{t:''}},
		{fn:'includes', vars:{t:'',val:''}}
	],
	"blanke-math":[
		{fn:'seed', vars:{low:'opt',high:'opt'}, args:'set/get rng seed'},
		{fn:'random', vars: { min:'opt', max:'opt' } },
		{fn:'indexTo2d', vars: { i:'', col:'' } },
		{fn:'getXY', vars: { angle:'', dist:'' } },
		{fn:'distance', vars:{x1:'',y1:'',x2:'',y2:''}},
		{fn:'lerp', vars:{a:'',b:'',t:''}},
		{fn:'sinusoidal', vars:{min:'',max:'',speed:'',offset:'opt'}},
		{fn:'angle', vars:{x1:'',y1:'',x2:'',y2:''}, args:'returns angle between two points abs(atan2)'},
		{fn:'pointInShape', vars:{shape:'{x1,y1,x2,y2,...}',x:'',y:''}}
	],
	"blanke-fs":[
		{fn:'basename',vars:{path:''}},
		{fn:'dirname',vars:{path:''}},
		{fn:'extname',vars:{path:''},info:'returns extension with period'},
		{fn:'removeExt',vars:{path:''},info:'removes .extension'},
		{fn:'ls',vars:{path:''},info:'lists files in path'}
	],
	"blanke-game":[
		{ prop: 'options' },
		{prop:'width'},
		{prop:'height'},
		{prop:'win_width'},
		{prop:'win_height'},
		{ prop: 'config' },
		{ fn: 'res', vars: { type:'image/audio/map', file:'' } },
		{ fn: 'spawn', vars: { classname:'', args:'opt' } },
		{ fn: 'setBackgroundColor', vars: { r:'', g:'', b:'', a:'' } },
		{prop:'updatables'},
		{prop:'drawables'}
	],
	"blanke-canvas-instance":[
		{ fn: 'resize', vars: { w:'', h:'' } },
		{ fn: 'drawTo', vars: { obj:'GameObject or function' } }
	],
	"blanke-image":[
		{ fn: 'info', vars: { name:'' } },
		{ fn: 'animation', vars: { file:'', animations:'{name,}', global_options:'' } }
	],
	"blanke-input":[
		{fn:'pressed',vars:{name:''}},
		{fn:'released',vars:{name:''}}
	],
	"blanke-draw":[
		{ fn: 'color' },
		{ fn: 'crop', vars: { x:'', y:'', w:'', h:'' } },
		{ fn: 'reset', vars: { only:'opt.color / transform / crop'} },
		{ fn: 'push' },
		{ fn: 'pop' },
		{ fn: 'stack', vars: { fn:'' } },
		{fn:'hexToRgb',vars:{hex:'string (#fff / #ffffff)'}}
	],
	"blanke-audio":[
		{ fn: 'play', vars: { names:'etc' } },
		{ fn: 'stop', vars: { names:'etc' } },
		{ fn: 'isPlaying', vars: { name:'' } }
	],
	"blanke-effect":[
		{ fn: 'new', vars: { options: '{ vars, code, effect, vertex }' } }
	],
	"blanke-camera":[
		{ fn: 'get', vars: { name:'' } },
		{ fn: 'attach', vars: { name:'' } },
		{ fn: 'detach' },
		{ fn: 'use', vars: { name:'', fn:'' }, info: 'attach -> fn -> detach' }
	],
	"blanke-map":[
		{ fn: 'load', vars: { file:'' } },
		{ fn: 'config', vars: { opt: '' } }
	],
	"blanke-map-instance":[
		{ fn: 'addTile', vars: {file:'',x:'',y:'',tx:'',ty:'',tw:'',th:'',layer:'opt'} },
		{ fn: 'spawnEntity', vars: {object_name:'',x:'',y:'',layer:'opt'} }
	],
	"blanke-physics":[
		{ fn: 'world', vars: {name:'',config:'opt'}},
		{ fn: 'joint', vars: {name:'',config:'opt'}},
		{ fn: 'body',  vars: {name:'',config:'opt'}},
		{ fn: 'setGravity', vars: {body:'',angle:'degrees',dist:''}}
	],
	"blanke-hitbox":[
		{ fn: 'add', vars: {obj:''}},
		{ fn: 'move', vars: {obj:''}, info:'call after changing x/y/hit_area'},
		{ fn: 'adjust', vars: {obj:'', left:'',top:'',width:'',height:''}, info:'resize a hitbox'},
		{ fn: 'remove', vars: {obj:''}}
	],
	"blanke-net":[

	],
	"blanke-timer":[
		{fn:"after",vars:{t:'seconds',fn:'return true to restart the timer'}},
		{fn:"every",vars:{t:'seconds',fn:'return true to destroy the timer'}}
	]
}