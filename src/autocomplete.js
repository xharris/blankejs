
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
let prop_effect = { prop: 'effect' };
let prop_visible = { prop: 'visible' };
let prop_pixi_point = (name) => ({ prop: 'point', info: '{ x, y, set(x, y=x) }' })

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#Keywords
// used Array.from(document.querySelectorAll("#Reserved_keywords_as_of_ECMAScript_2015 + .threecolumns code")).map((v)=>"'"+v.innerHTML+"'").join(',')
module.exports.keywords = [
	'break','case','catch','class','const','continue','debugger','default','delete',
	'do','else','export','extends','finally','for','function','if','import','in',
	'instanceof','new','return','super','switch','this','throw','try','typeof',
	'var','void','while','with','yield'
]

// TestScene is included just so it looks nice
module.exports.class_list = [
	'Asset','Game','Util','Draw','Scene',
	'Map','Effect','Scene','Sprite','Input',
	'Entity','View','TestScene','TestView'
];

module.exports.class_extends = {
    'entity': /\bclass\s+(\w+)\s+extends\s+Entity/g
}

module.exports.instance = {
	'entity': [
		/\b(\w+)\s*=\s*new\s+<class_name>\s*\(/g,
		/\b(\w+)\s*=\s*(?:\w+)\s*\.\s*spawnEntity\s*\(\s*<class_name>\s*,/g
	],
	'map': /\b(\w+)\s*=\s*Map\.load\([\'\"].+[\'\"]\)\s+?/g,
	'draw': /\b(\w+)\s*=\s*new\s+Draw\s*\(/g,
	'sprite': /\b(\w+)\s*=\s*new\s+Sprite\s*\(\s*\{[\s\w\[\]:"',.]+\}\s*\)/g,
	'view': [
		/\b(\w+)\s*=\s*View\s*\([\s\w"']+\)/g,
		/\b(\w+)\s*=\s*TestView\s*\([\s\w"',]+\)/g
	]
}

module.exports.user_words = {
	'var':[
		// single var
		/([a-zA-Z_]\w+?)\s*=\s(?!function|\(\)\s*=>)/g,
		/(?:let|var)\s+([a-zA-Z_]\w+)/g,
		// comma separated var list
		/(?:let|var)\s+(?:[a-zA-Z_]+[\w\s=]+?,\s*)+([a-zA-Z_]\w+)(?!\s*=)/g
	],
	'fn':[
		// var = function
		/([a-zA-Z_]\w+?)\s*=\s(?:function|\(\)\s*=>)/g,
		// function var()
		/function\s+([a-zA-Z_]\w+)\s*\(/g
	]
}

module.exports.image = [
	/Sprite\(["']([\w\s\/.-]+)["']\)/,
	/self:addSprite[\s\w{(="',]+image[\s=]+['"]([\w\s\/.-]+)/,
	/Sprite[\s\w{(="',]+image[\s=]+['"]([\w\s\/.-]+)/
];

/*
	{ fn: "name", info, vars }
	{ prop: "name", info }

	- info: "description"
	- vars: { arg1: 'default', arg2: 'description', etc: '' }
*/
module.exports.hints = {
	"global":[
		{ fn: "Scene", vars: { name:'', callbacks:'{ onStart, onUpdate, onEnd }' } }
	],
	"blanke-game":[
		{ prop: 'width' },
		{ prop: 'height' },
		{ prop: 'background_color', info: 'getter/setter' },
		{ fn: 'end' }
	],
	"blanke-util":[
		{ fn: 'rad', vars: { deg:'' }, info: 'converts degrees to radians' },
		{ fn: 'deg', vars: { rad:'' }, info: 'converts radians to degrees' },
		{ fn: 'direction_x', vars: { angle:'degrees', dist:'' } },
		{ fn: 'direction_y', vars: { angle:'degrees', dist:'' } },
		{ fn: 'distance', vars: { x1:'', y1:'', x2:'', y2:'' } },
		{ fn: 'direction', vars: { x1:'', y1:'', x2:'', y2:'' } },
		{ fn: 'rand_range', vars: { min:'', max:'' } },
		{ fn: 'basename', vars: { path:'', no_ext:'' } },
		{ fn: 'lerp', vars: { a:'', b:'', amt:'[0,1]' } },
		{ fn: 'sinusoidal', vars: { min:'', max:'', spd:'', offset:'opt' } }
	],
	"blanke-asset":[
		{ prop: 'supported_filetypes', info: '{ type : [extensions] }' },
		{ prop: 'base_textures', info: '{ path : Pixi.Texture }' },
		{ fn: 'parseAssetName', info: 'turns a path into an asset keyname' },
		{ fn: 'getName', vars: { type:'', path:'' } },
		{ fn: 'getPath', vars: { type:'', name:'' } },
		{ fn: 'add', vars: { path:'', options:'' } },
		{ fn: 'load', info: 'loads everything added (Asset.add) and calls cb() when done', vars: { cb:'' } },
		{ fn: 'audioSprite', info: 'creates HowlerJS sprites', vars: { name:'asset name', sprites:'{ name: [start, stop] }' } },
		{ fn: 'texCrop', info: `returns</br>
{</br>
&nbsp;&nbsp; key: tex_crop_cache key,</br>
&nbsp;&nbsp; frames: [[x,y,w,h]],</br>
&nbsp;&nbsp; tex_frames: [cropped Pixi.Texture's]</br>
}`, vars: {} }
	],
	"blanke-draw":[
		{ fn: 'hex', vars: { rgb: '[r,g,b]' } },
		{ fn: 'rgb', vars: { hex: '#FFFFFF (case-insensitive)'}},
		...['red','pink','purple',
			'indigo','baby_blue','blue',
			'dark_blue','green','yellow',
			'orange','brown','gray','grey',
			'black','white','black2','white2'].map(c=>({ prop: c }))
	],
	"blanke-draw-instance":[
		...prop_xyz,
		prop_effect,
		prop_visible,
		{ fn: 'draw', vars: { instruction:'see docs for possible drawings', etc:'' } },
		{ prop: 'auto_clear', info: 'clear before every draw()' },
		{ fn: 'clone', info: 'returns new Draw instance' },
		{ fn: 'containsPoint', vars: { x:'', y:'' } },
		{ fn: 'clear' },
		{ fn: 'destroy' }
	],
	"blanke-scene":[
		{ fn: 'switch', vars: { name:'' } },
		{ fn: 'start', info: 'does not end previous scene.</br>recommended: use Scene.switch()', vars: { name: '' } },
		{ fn: 'end', vars: { name:'' } },
		{ fn: 'endAll' },
		{ prop: 'stack', info: 'contains list of currently active scene names' }
	],
	"blanke-sprite-instance":[
		...prop_xyz,
		prop_effect,
		{ prop: 'alpha' },
		{ prop: 'width' },
		{ prop: 'height' },
		prop_pixi_point('pivot'),
		{ prop: 'angle', info: 'degrees' },
		{ fn: 'destroy' }
	],
	"blanke-map":[
		{ fn: 'load', vars: { name:'map asset' } }
	],
	"blanke-map-instance":[
		{ prop: 'debug' },
		...prop_xyz,
		prop_effect,
		{ fn: 'addLayer', vars: { name:'' } },
		{ fn: 'addTile', vars: { name:'image asset', position:'[x, y, x, y, ...]', options:'{ layer }' } },
		{ fn: 'addEntity', vars: { entity_class:'', x:'', y:'', options:'{ layer, align (left, right, top, bottom, center) }' } },
		{ fn: 'addHitbox', vars: { hitbox_args:'' } },
		{ fn: 'removeTile', vars: { name:'image asset', position:'[x, y, x, y, ...]', layer:'' } }
	],
	"blanke-entity-instance":[
		...prop_xyz,
		prop_visible,
		{ prop: 'hspeed' },
		{ prop: 'vspeed' },
		{ prop: 'gravity' },
		{ prop: 'gravity_direction' },
		{ prop: 'shape_index', info:'base shape of the entity' },
		{ prop: 'shapes', info:`{ 'shape_name' : Hitbox }`},
		prop_effect
	],
	"blanke-input":[
		{ fn: 'set', vars: { name:'', inputs:'...' } },
		{ fn: 'on', vars: { event:'', object:'opt', callback:'' }},
		{ prop: 'stop_propagation', info: 'automatically stop event propagation? (default: true)' }
	],
	"blanke-view-instance":[
		...prop_xy
	]
}