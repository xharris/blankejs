# What is a scene?

>Also known as a 'state', scenes can be used to organize the game into separate, contained sections.

Examples of scenes:

_`ScnMainMenu`_ displays choices to the player such as 'play', 'options', and 'quit'

_`ScnPlay`_ where the actual gameplay happens (flying around in a ship, shooting stuff)

>The name 'ScnPlay' can be anything: ScenePlay, Play, SceneWhereThingsHappen. I've named it 'ScnPlay' so that it's easier to find in the search box and still describes what it is.

# Usage

## Create a new scene

__Search `Add a scene`__

This creates a scene equipped with several [callback functions](https://en.wikipedia.org/wiki/Callback_(computer_programming)#JavaScript):

* `onStart(scene)` : called once at the start of the scene

* `onUpdate(scene, dt)` : called every frame

* `onEnd(scene)` : called once when the scene is switched or just flat-out ended

## Start the scene

In the __Settings__, you can change the value of __first_scene__

## Switching to other scenes

`Scene.switch('ScnName')` 