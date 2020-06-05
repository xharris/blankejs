## Time

```
Time.format("%hhr %mmin %ssec. \n\n", Game.time * 1000)
-- prints "0hr 3min 59sec" (or whatever time it gives you)
```

# Methods 

`Time.format(str, ms)` 

* `str` time formatting
  * `%%d` days
  * `%%h` hours
  * `%%m` minutes
  * `%%s` seconds

`Time.ms(opt{})`

* `opt{ ms, sec, min, hr, day }`