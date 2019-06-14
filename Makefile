.PHONY: dist dist-mac

do:
	make -B blanke

web:
	start "" http://localhost:8000 || open http://localhost:8000
	cd blankejs && python -m SimpleHTTPServer 8000

setup:
	# npm install -g pnpm
	pnpm install
	sudo pnpm install -g less
	sudo pnpm install -g nw@^0.36.2-sdk

clean:
	-rm -rf node_modules
	-rd -r -fo "node_modules"
	npm uninstall -g nw
	make -B setup

dist:
	npm run less
	pnpm run dist

dist-mac:
	pnpm run less
	pnpm run dist-mac

love:
	love2d/love.exe projects/penguin

blanke:
	pnpm run less
	pnpm run electron
	
engine:
	cp -r love2d dist/BlankE-0.1.0-win-x86/love2d

distrib:
	rm -rf nwjs-build64/src
	cp -r src nwjs-build64/src
	cp package.json nwjs-build64/package.json
