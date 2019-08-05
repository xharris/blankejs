
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
	prop_z,
	{ fn: 'getRect', info: 'returns a bounding box Rectangle'},
	{ prop: 'rect', info: 'get/set Rectangle for object\'s hitArea' },
	{ prop: 'visible' },
	{ prop: 'effect' },
	{ fn: 'getTexture', info: 'returns a PIXI.Teture' }
]

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
	'Map','Effect','Sprite','Input',
	'Entity','View','Timer',
	'TestScene','TestView'
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

module.exports.this_ref = {
	'blanke-entity-instance':/\bclass\s+\w+\s+extends\s+Entity/g,
	'blanke-scene':/\b(?:onStart|onUpdate|onEnd)[:\s\w]*\(([a-zA-Z_]\w*)\s*[),]/g
}

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
		{ prop: 'time', info: 'elapsed dt' },
		{ prop: 'ms', info: 'elapsed ms' },
		{ prop: 'os', info: 'ide/win/mac/linux/android/ios' },
		{ prop: 'width' },
		{ prop: 'height' },
		{ prop: 'background_color', info: 'get/set' },
		{ prop: 'paused', info: 'whether game is paused or not' },
		{ fn: 'pause', info: '[!] for use in IDE' },
		{ fn: 'resume', info: '[!] for use in IDE' },
		{ fn: 'step', info: '[!] for use in IDE' },
		{ prop: 'fullscreen', info: 'get/set. will not work in IDE mode'},
		{ fn: 'end' }
	],
	"blanke-util":[
		{ fn: 'uuid' },
		{ fn: 'aliasProps', vars: { dest:'', src:'', properties:'' }, info: 'maps get/set functions that allow dest to control [properties] of src' },
		{ fn: 'rad', vars: { deg:'' }, info: 'converts degrees to radians' },
		{ fn: 'deg', vars: { rad:'' }, info: 'converts radians to degrees' },
		{ fn: 'direction_x', vars: { angle:'degrees', dist:'' } },
		{ fn: 'direction_y', vars: { angle:'degrees', dist:'' } },
		{ fn: 'distance', vars: { x1:'', y1:'', x2:'', y2:'' } },
		{ fn: 'direction', vars: { x1:'', y1:'', x2:'', y2:'' } },
		{ fn: 'rand_range', info: 'returns int [min,max)', vars: { min:'', max:'' } },
		{ fn: 'rand_choose', vars: { array:'' } },
		{ fn: 'basename', vars: { path:'', no_ext:'' } },
		{ fn: 'lerp', vars: { a:'', b:'', amt:'[0,1]' } },
		{ fn: 'sinusoidal', vars: { min:'', max:'', spd:'', offset:'opt' } },
		{ fn: 'str_count', vars: { string:'', substring:'', allowOverlap:'' } }
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
		{ fn: 'draw', vars: { instruction:'see docs for possible drawings', etc:'' } },
		{ prop: 'auto_clear', info: 'clear before every draw()' },
		{ fn: 'clone', info: 'returns new Draw instance' },
		{ fn: 'containsPoint', vars: { x:'', y:'' } },
		{ fn: 'clear' },
		{ fn: 'destroy' },
		...prop_gameobject
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
		{ prop: 'alpha' },
		{ prop: 'width' },
		{ prop: 'height' },
		prop_pixi_point('pivot'),
		{ prop: 'angle', info: 'degrees' },
		{ fn: 'destroy' },
		...prop_gameobject
	],
	"blanke-map":[
		{ fn: 'load', vars: { name:'map asset' } }
	],
	"blanke-map-instance":[
		{ prop: 'debug' },
		...prop_xyz,
		{ fn: 'addLayer', vars: { name:'' } },
		{ fn: 'addTile', vars: { name:'image asset', position:'[x, y, x, y, ...]', options:'{ layer }' } },
		{ fn: 'addEntity', vars: { entity_class:'', x:'', y:'', options:'{ layer, align (left, right, top, bottom, center) }' } },
		{ fn: 'addHitbox', vars: { hitbox_args:'' } },
		{ fn: 'removeTile', vars: { name:'image asset', position:'[x, y, x, y, ...]', layer:'' } },
		...prop_gameobject
	],
	"blanke-entity-instance":[
		...prop_xyz,
		{ prop: 'hspeed' },
		{ prop: 'vspeed' },
		{ prop: 'gravity' },
		{ prop: 'gravity_direction', info: '0 = right, 90 = down'},
		{ prop: 'shape_index', info:'base shape of the entity' },
		{ prop: 'shapes', info:`{ 'shape_name' : Hitbox }`},
		{ prop: 'sprite_align', info: `changes sprite_pivot with a combination of 'left right top bottom center'`},
		{ fn: 'addSprite', vars: { name: '', options: 'frames, columns, frame_size[w,h], speed, spacing[x,y], offset[x,y]' } },
		{ fn: 'addShape', vars: { name: '',  options: 'type(circle/rect/poly), ...see docs' } },
		...prop_gameobject
	],
	"blanke-input":[
		{ fn: 'set', vars: { name:'', inputs:'...' } },
		{ fn: 'on', vars: { event:'', object:'opt', callback:'' }},
		{ prop: 'stop_propagation', info: 'automatically stop event propagation? (default: true)' }
	],
	"blanke-view-instance":[
		...prop_xy,
		{ prop: 'port_x' },
		{ prop: 'port_y' },
		{ prop: 'port_width' },
		{ prop: 'port_height' }, 
		{ fn: 'follow', vars: { obj:'any object with an x and y value' } },
		{ prop: 'xoffset' },
		{ prop: 'yoffset' },
		prop_pixi_point('scale'),
		{ prop: 'angle', info: 'degrees' },
		...prop_gameobject
	]
}