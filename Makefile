do:
	lessc --strict-math=on src/less/main.less src/main.css
	nw .
	
distrib:
	cp -r src nwjs-build64/src
	cp package.json nwjs-build64/package.json