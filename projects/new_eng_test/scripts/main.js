Asset.add([
	["assets/image/player_stand.png"],
	["assets/image/ground.png"],
	//["assets/maps/level1.map"],
	['assets/image/sprite-example.png',{name:'luigi_walk',offset:[9,54],speed:0.2,frame_size:[27,49],frames:3,columns:3}]
]);

Input.set("move_left","left","a");
Input.set("move_right","right","d");
Input.set("move_up","up","w");
Input.set("move_down","down","s");