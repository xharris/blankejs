# Class methods

`Timer.after(seconds, fn)` returning true in `fn` will __restart__ the timer

`Timer.every(seconds, fn)` returning true in `fn` will __destroy__ the timer

* fn is called as `fn(timer)` where timer is the current timer

# Timer properties/methods

* fn: function to be called
* duration: initial starting value
* t: current timer position
* paused: true/false
* destroy()