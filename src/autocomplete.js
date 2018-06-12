// Group 1: name of class to replace <class_name> in instance_regex
module.exports.class_regex = {
	'state': 	/.*BlankE\.addClassType\s*\(\s*"(\w+)"\s*,\s*"State"\s*\).*/g,
	'entity': 	/.*BlankE\.addClassType\s*\(\s*"(\w+)"\s*,\s*"Entity"\s*\).*/g,
	'blanke': 	/.*(BlankE).*/g
}

// Group 1: name of instance 
module.exports.instance_regex = {
	'state': 	/\b(\w+)\s*=\s*<class_name>\(\).*/g,
	'entity': 	/\b(\w+)\s*=\s*<class_name>\(\).*/g,
}

module.exports.completions = {
	"blanke-blanke":[
		{fn:"addClassType",
		vars:{
			arg1:'MenuState / Player / ...', arg2:'State / Entity / etc.'
		}}
	],
	"blanke-state":[
		{fn:"switch",
		vars:{
			name: "name of state to switch to"
		}},
		{fn:"transition"},
		{fn:"current"},
		{fn:"enter", callback: true}
	],
	"blanke-entity-instance":[
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

		{prop:"direction"},
		{prop:"friction"},
		{prop:"gravity"},
		{prop:"gravity_direction"},
		{prop:"hspeed"},
		{prop:"vspeed"},
		{prop:"speed"},
		{prop:"xprevious"},
		{prop:"yprevious"},
		{prop:"xstart"},
		{prop:"ystart"},

		{fn:"destroy"},

		{fn:"hadCollision",vars:{self_name:'', other_name:''}},
		{fn:"getCollisions",vars:{shape_name:''}},
		{fn:"debugSprite",vars:{sprite_index:''}},
		{fn:"debugCollision"}
	]
}