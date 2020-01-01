
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
module.exports.keywords = [
	'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 
	'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 
	'until', 'while'
]

// TestScene is included just so it looks nice
module.exports.class_list = [
	"Math", "FS", "Game", "Canvas", "Image", "Entity",
	"Input", "Draw", "Color", "Audio", "Effect", "Camera",
	"Map", "Physics", "Hitbox", "State", "Window", "Net",
	"Blanke"
];

module.exports.class_extends = {
    'entity': /\bEntity\s+[\'\"](\w+)[\'\"]\s*,/g
}

module.exports.instance = {
	'entity': /\b(\w+)\s*=\s*Game\.spawn\(\s*[\'\"]<class_name>[\'\"]\s*\)/g,
	'map': /\b(\w+)\s*=\s*Map\.load\([\'\"].+[\'\"]\)/g,
	'canvas': /(@?\w+)\s*(?::|=)\s*Canvas[\s\(]/g
}

module.exports.user_words = {
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
	]
}

module.exports.image = [
	/images[\s=]+\{\s*['"]([\w\s\/.-]+)['"]/,
	/Image\.animation\s*\(\s*['"]([\w\s\/.-]+)['"]/

];

module.exports.this_ref = {
	'blanke-entity-instance':/\bEntity\s+[\'\"]\w+[\'\"]\s*,/g
}

/*
	{ fn: "name", info, vars }
	{ prop: "name", info }

	- info: "description"
	- vars: { arg1: 'default', arg2: 'description', etc: '' }
*/
module.exports.hints = {
	"global":[
		{ fn: "Draw", vars: { args:'...' } }
	],
	"blanke-math":[
		{ fn: 'random', vars: { min:'opt', max:'opt' } },
		{ fn: 'indexTo2d', vars: { i:'', col:'' } },
		{ fn: 'getXY', vars: { angle:'', dist:'' } }
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
		{ prop: 'config' },
		{ fn: 'res', vars: { type:'image/audio/map', file:'' } },
		{ fn: 'spawn', vars: { classname:'', args:'opt' } },
		{ fn: 'setBackgroundColor', vars: { r:'', g:'', b:'', a:'' } }
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
		{ fn: 'world', vars: {name:'',config:''}},
		{ fn: 'joint', vars: {name:'',config:''}},
		{ fn: 'body',  vars: {name:'',config:''}},
		{ fn: 'setGravity', vars: {body:'',angle:'degrees',dist:''}}
	],
	"blanke-hitbox":[
		{ fn: 'add', vars: {obj:''}},
		{ fn: 'move', vars: {obj:''}, info:'call after changing x/y/hitArea'},
		{ fn: 'remove', vars: {obj:''}}
	],
	"blanke-net":[

	]
}