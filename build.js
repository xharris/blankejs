var nwBUILD = require('%AppData%\\npm\\node_modules\\nw-builder');
console.log(nwBUILD)

var nw = new nwBUILD({
	files: './src/**/**',
	platforms: ['win32'],
	flavor: 'normal',
	winIco: './src/logo.ico'
});

nw.build().then(function(err){
	if (err) console.log(err);
	console.log('finished building!');
});