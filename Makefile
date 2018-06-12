do:
	make blanke

love:
	love2d/love.exe projects/penguin

blanke:
	npm run less
	npm run nw
	
distrib:
	rm -rf nwjs-build64/src
	cp -r src nwjs-build64/src
	cp package.json nwjs-build64/package.json