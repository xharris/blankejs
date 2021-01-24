## Audio

```
Audio('fire.mp3', {
    name = 'lots_of_fire',
    looping = true
}, {
    name = 'little_fire',
    volume = 0.2
})

Audio.hearing(7)
Audio.position{ x = camera.x, z = camera.y } -- not a typo

aud_fire = Audio.play('lots_of_fire', {
    position = { x = entityfire.x, z = entityfire.y }
})
```

# Class Methods

`play(name, [options])` returns a Source instance

`stop([names...])` stops certain audio or all of them if no names are given

`isPlaying(name)`

`hearing(v)` larger v = better listener hearing. Used with positional audio.

`source(name, [options])` returns a Source instance that will not be managed by the Audio class (will not be auto-played)

# Config properties

`Audio(file, { ...config1 }, { ...config2 }, ...)`

* type ('static'/'stream') : use 'stream' for long music and 'static' for short sound effects
* looping (t/f)
* volume [0, infinity] : please don't try ridiculously high numbers :)
* pitch
* relative
* rolloff
* position { x, y, z } : position of listener
* attenuationDistances
* cone
* direction
* velocity
* filter
* effect
* volumeLimits
* airAbsorption

# Source methods 

> a Source instance is returned from Audio.play and Audio.source

`set<method_name>` or `get<method_name>`

Replace `<method_name>` with a config property.

For example:

> if you create an audio source: `local my_audio = Audio.play('mysong.ogg')`
>
> * `Audio.volume(0.5)` would be similar to `my_audio:setVolume(0.5)` or `0.5 = my_audio:getVolume()`
>
> * `Audio.position{x=1, y=2, z=3}` would be similar to `my_audio:setPosition{x=1, y=2, z=3} / 1,2,3 = my_audio:getPosition()`
