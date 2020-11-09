[![TravisCI](https://travis-ci.org/xharris/blankejs.svg?branch=master)](https://travis-ci.org/github/xharris/blankejs)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fxharris%2Fblankejs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fxharris%2Fblankejs?ref=badge_shield)

# Installation notes

npm install
- might need to install electron globally, idk

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

- [Lua Engine license (MIT)](https://github.com/xharris/blankejs/blob/master/love2d/lua/blanke/LICENSE.md)

- [Lua Engine dependencies](https://github.com/xharris/blankejs/blob/master/love2d/lua/blanke/CREDITS.md)

- The IDE [End-User License Agreement (EULA)](https://github.com/xharris/blankejs/blob/master/EULA.txt)
