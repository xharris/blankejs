do:
	make -B blanke

setup:
	npm install
	npm install less -g
	git submodule init
	git submodule update

love:
	love2d/love.exe projects/penguin

blanke:
	npm run less
	npm run nw
	
engine:
	cp -r love2d dist/BlankE-0.1.0-win-x86/love2d

distrib:
	rm -rf nwjs-build64/src
	cp -r src nwjs-build64/src
	cp package.json nwjs-build64/package.json