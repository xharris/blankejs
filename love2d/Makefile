install:
	cd luarocks-3.2.1-win32 && cmd /c INSTALL /P D:\Documents\PROJECTS\blankejs\love2d\luarocks /SELFCONTAINED /L /F

runw:
	.\luarocks-3.2.1-windows-32\luarocks.exe --lua-dir 'D:/Documents/PROJECTS/blankejs/love2d' --lua-version=5.1

buildw:
	./moon/bin/moon game.moon

runl:
	moon main.moon game.moon blanke.moon
	moonc main.moon

install_linux:
	sudo add-apt-repository ppa:bartbes/love-stable
	sudo apt-get update
	sudo apt install luarocks love
