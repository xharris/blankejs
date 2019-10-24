.PHONY: dist dist-mac

do:
	make -B blanke

version:
	-git tag -d ${v}
	git tag -a ${v} -m"setting latest version to ${v}"
	git push origin ${v} -f

setup:
	# npm install -g pnpm
	npm install
	sudo npm install -g less

clean:
	-rm -rf node_modules
	-rd -r -fo "node_modules"
	npm uninstall -g nw
	make -B setup

dist:
	npm run dist

blanke:
	npm run electron

install_butler_mac:
	curl -L -o butler.zip https://broth.itch.ovh/butler/darwin-amd64/LATEST/archive/default
	unzip butler.zip -d butler
	rm butler.zip
	-chmod +x ./butler/butler
	./butler/butler login

install_butler_win:
	node ./getbutler.js

upload:
	./butler/butler push ./dist/BlankE.zip xhh/blanke:${channel} --userversion ${v}

upload_mac:
	-rm ./dist/BlankE.zip
	cd ./dist && tar cf - BlankE-darwin-x64 | zip -9 -X BlankE -
	make -B upload v=${v} os=darwin-x64 channel=osx-univeral

upload_win:
	node ./zip.js
	make -B upload v=${v} os=win32-x64 channel=win-universal

