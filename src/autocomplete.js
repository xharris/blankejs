
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
	"class", "extends", "if", "then", "super", "do", "with",
	"import", "export", "while", "elseif", "return", "for",
	"in", "from", "when", "using", "else", "and", "or", "not",
	"switch", "break"
]

// TestScene is included just so it looks nice
module.exports.class_list = [
	'Blanke','Game','Canvas','Image','Entity',
	'Inputs','Draw','Audio','Effect','Math',
	'Map','Physics','Hitbox'
];

module.exports.class_extends = {
    'entity': /\bEntity\s+[\'\"](\w+)[\'\"]\s*,/g
}

module.exports.instance = {
	'entity': /\b(\w+)\s*=\s*Game\.spawn\(\s*[\'\"]<class_name>[\'\"]\s*\)/g,
	'map': /\b(\w+)\s*=\s*Map\.load\([\'\"].+[\'\"]\)/g,
	'sprite': /\b(\w+)\s*=\s*new\s+Sprite\s*\(\s*\{[\s\w\[\]:"',.]+\}\s*\)/g
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
	/Sprite\(["']([\w\s\/.-]+)["']\)/,
	/this\.addSprite\s*\(\s*['"][\w\s\/.-]+['"]\s*,\s*{[\s\w"',:]*image\s*:\s*['"]([\w\s\/.-]+)['"]/,
	/new\s+Sprite[\s\w{(:"',]+image[\s:]+['"]([\w\s\/.-]+)/
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
		{ fn: "Scene", vars: { name:'', callbacks:'{ onStart, onUpdate, onEnd }' } },
		{ fn: "Draw", vars: { args:'...' } }
	],
	"blanke-util":[
		{ fn: 'uuid' },
		{ fn: 'repeat', vars: { i:'', function:'return true to stop early' } },
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
	"blanke-canvas-instance":[
		{ prop: 'width' },
		{ prop: 'height' },
		{ prop: 'auto_clear' },
		...prop_xyz,
		{ prop: 'alpha' },
		{ prop: 'hitArea' },
		prop_pixi_point('scale'),
		{ fn: 'destroy' },
		{ fn: 'clear' },
		{ fn: 'draw', vars: { obj:'opt' } },
		{ fn: 'resize', vars: { width:'', height:'' } }
	],
	"blanke-scene":[
		{ fn: 'switch', vars: { name:'' } },
		{ fn: 'start', info: 'does not end previous scene.</br>recommended: use Scene.switch()', vars: { name: '' } },
		{ fn: 'end', vars: { name:'' } },
		{ fn: 'endAll' },
		{ prop: 'stack', info: 'contains list of currently active scene names' },
		...prop_gameobject
	],
	"blanke-sprite-instance":[
		...prop_xyz,
		{ prop: 'alpha' },
		{ prop: 'width' },
		{ prop: 'height' },
		prop_pixi_point('pivot'),
		{ prop: 'angle', info: 'degrees' },
		{ prop: 'align', info: 'center/left/right center/top/bottom' },
		{ prop: 'speed', info: 'animation speed' },
		{ prop: 'frame', info: 'animation frame index' },
		{ prop: 'frames' },
		{ fn: 'reset', info: 'resets all transforms' },
		{ fn: 'crop', vars: { x:'', y:'', w:'', h:'' }, info: 'returns a new Sprite' },
		{ fn: 'chop', vars: { w:'', h:'' }, info: 'returns array of Sprites' },
		{ fn: 'destroy' },
		...prop_gameobject
	],
	"blanke-hitbox-instance":[
		{ prop: 'type', info: 'circle/rect/poly' },
		{ prop: 'tag' },
		{ prop: 'shape' },
		...prop_xyz,
		...prop_gameobject,
		{ fn: 'move', vars: { dx:'', dy:'' } },
		{ fn: 'position', vars: { x:'', y:'' } },
		{ fn: 'collisions', info: 'returns array of [Hitbox, {sep_vec: {x, y}}]' },
		{ fn: 'repel', vars: { hitbox:'' } },
		{ fn: 'destroy' }
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
		{ fn: 'spawnEntity', vars: { entity_class:'', object_name:'' } },
		{ fn: 'spawnHitbox', vars: { object_name:'', layer:'opt' } },
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
		{ prop: 'sprite_alpha' },
		{ prop: 'sprite_width' },
		{ prop: 'sprite_height' },
		prop_pixi_point('sprite_pivot'),
		{ prop: 'sprite_angle', info: 'deg' },
		prop_pixi_point('sprite_scale'),
		prop_pixi_point('sprite_skew'),
		{ prop: 'sprite_frame' },
		{ prop: 'sprite_frames' },
		prop_pixi_point('sprite_anchor'),
		{ fn: 'addSprite', vars: { name: '', options: 'frames, columns, frame_size[w,h], speed, spacing[x,y], offset[x,y]' } },
		{ fn: 'addShape', vars: { name: '',  options: `type ('circle/rect/poly') || { type, tag, shape ([x,y,w,h]/[x,y,r]) }` } },
		{ prop: 'onCollision', info: `(Hitbox, { sep_vec: {x, y} }` },
		...prop_gameobject
	],
	"blanke-input":[
		{ fn: 'set', vars: { name:'', inputs:'...' } },
		{ fn: 'on', vars: { event:'', object:'opt', callback:'' }},
		{ prop: 'stop_propagation', info: 'automatically stop event propagation? (default: true)' },
		{ prop: 'mouse' }
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
	],
	"blanke-event":[
		{ fn: 'emit', vars: { name:'', args:'...' } },
		{ fn: 'on', vars: { name:'', fn:'' }, info: 'fn(...args) will be called when emit(name, ...args) is called' },
		{ fn: 'off', vars: { name:'', fn:'' } }
	],
	"blanke-timer":[
		{ fn: 'after', vars: { ms:'', func:'' } },
		{ fn: 'every', vars: { ms:'', func:'return true to stop this from running' } }
	],

	"blanke-math":[
		{ fn: 'random', vars: { min:'opt', max:'opt' } },
		{ fn: 'indexTo2d', vars: { i:'', col:'' } },
		{ fn: 'getXY', vars: { angle:'', dist:'' } }
	],
	"blanke-game":[
		{ prop: 'options' },
		{ prop: 'config' },
		{ fn: 'res', vars: { type:'image/audio/map', file:'' } },
		{ fn: 'spawn', vars: { classname:'', args:'opt' } },
		{ fn: 'setBackgroundColor', vars: { r:'', g:'', b:'', a:'' } }
	]
}