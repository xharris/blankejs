# Installation notes

npm install

(if there are problems running 'nw .') npm install nw --nw_build_type=sdk

git submodule init

git submodule update

install Love2D on linux:

- use sudo apt-get install love
- do not use Snap to install. permissions will not be set up properly

Error: "System limit for number of file watchers reached"

```
$ sudo sysctl fs.inotify.max_user_watches=524288
$ sudo sysctl -p
```

src: https://github.com/guard/listen/wiki/Increasing-the-amount-of-inotify-watchers#the-technical-details

# License

- [Software dependencies](https://github.com/xharris/blankejs/blob/master/package.json)

- [Engine dependencies]()

- There is an [End-User License Agreement (EULA)](https://github.com/xharris/blankejs/blob/master/EULA.txt)

- There are plans for free/indie/educational licenses
