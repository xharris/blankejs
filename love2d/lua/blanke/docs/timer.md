# What is Timer?

**Timer** can be used to time things. Perform an action after x seconds or every x seconds.

>Example
>```
>Timer(5).every(1, function(t)
>	some_text = "t-minus " .. t .. " seconds"
>end):after(function()
>	some_text = "blastoff"
>end):start()
>```
> or
> 
>`Timer.every(1, function() beep() end)`

**Note**: not everything has to been called in a condense manner as shown above. Timer(num) returns a a timer instance that can be stored in a variable.

# Initialization

`Timer([duration])` will just give you a timer object

These are shortcut methods:

```
Timer.every(seconds, fn)
Timer.after(seconds, fn)
```

They return a Timer object and automatically start it.

# Props

```
duration		-- seconds
time			-- time elapsed after timer has started
countdown		-- readonly. the inverse of 'time', aka. how many seconds are 
running			-- whether or not the timer is currently running
iterations		-- readonly. how many times start() has been called
```

# Methods

```
before([delay], function)				-- starts immediately unless delay is supplied
every([interval], function)				-- interval=1 , function happens on every interal
after([delay], function)				-- happens after `duration` supplied to constructor with optional delay
start()									-- MUST BE CALLED TO START THE TIMER. DO NOT FORGET THIS OR YOU WILL GO NUTS
```