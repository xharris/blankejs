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

# Source methods (returned from Audio.play)

`set<method_name>` or `get<method_name>`

* Looping
* Volume
* AirAbsorption
* Pitch
* Relative
* Rolloff
* Position
* AttenuationDistances
* Cone
* Direction
* Vecolity
* Filter
* Effect
* VolumeLimits