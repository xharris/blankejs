[![TravisCI](https://travis-ci.org/xharris/blankejs.svg?branch=master)](https://travis-ci.org/github/xharris/blankejs)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fxharris%2Fblankejs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fxharris%2Fblankejs?ref=badge_shield)

# Installation notes

npm install

(if there are problems running 'nw .') npm install nw --nw_build_type=sdk

git submodule init

git submodule update

install Love2D on linux:

- use sudo apt-get install love
- do not use Snap to install. permissions will not be set up properly

# Errors

## Error: "System limit for number of file watchers reached"

```
$ sudo sysctl fs.inotify.max_user_watches=524288
$ sudo sysctl -p
```

## Error: EPERM: operation not permitted, open "<script_path>"

1. open file explorer and look at file properties

2. uncheck 'read-only'

src: https://github.com/guard/listen/wiki/Increasing-the-amount-of-inotify-watchers#the-technical-details

# License

- [Software dependencies](https://github.com/xharris/blankejs/blob/master/package.json)

- [Engine dependencies](https://github.com/xharris/blankejs/blob/master/love2d/license.md)

- There is an [End-User License Agreement (EULA)](https://github.com/xharris/blankejs/blob/master/EULA.txt)

- There are plans for free/indie/educational licenses
