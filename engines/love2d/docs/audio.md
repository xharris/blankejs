## Audio

```
Audio 'fire.mp3', {
    name: 'lots_of_fire',
    looping: true
}, {
    name: 'little_fire',
    volume: 0.2
}

aud_fire = Audio.play('lots_of_fire')
```

# Class Methods

`play(name,...)` returns an audio source or a list (if multiple are played)

`stop([names...])` stops certain audio or all of them if no names are given

`isPlaying(name)`

# Config properties

`Audio(file, { ...config1 }, { ...config2 }, ...)`

* looping (t/f)
* volume [0, infinity] : please don't try ridiculously high numbers :)
* pitch
* relative
* rolloff
* position
* attenuationDistances
* cone
* direction
* velocity
* filter
* effect
* volumeLimits
* airAbsorption

# Source methods (returned from Audio.play)

`set<method_name>` or `get<method_name>`

Replace `<method_name>` with a config property. 

For example:

> if you create an audio source: `local my_audio = Audio.play('mysong.ogg')`
> 
> * `volume` becomes `my_audio:setVolume(v) / v = my_audio:getVolume()`
> 
> * `position` becomes `my_audio:setPosition(x,y,z) / x,y,z = my_audio:getPosition()`