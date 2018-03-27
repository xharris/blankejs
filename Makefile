do:
	make blanke

love:
	love2d/love.exe projects/penguin

blanke:
	lessc --strict-math=on src/less/main.less src/main.css
	nw .
	
distrib:
	rm -rf nwjs-build64/src
	cp -r src nwjs-build64/src
	cp package.json nwjs-build64/package.json