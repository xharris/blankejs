# class properties

`address = 'localhost'`

`port = 8080`

`room = 1`

# class methods

`connect([address, port])`

`disconnect()`

`connected()` returns __true__ if connected

`send(data)` data can be anything

`spawn(obj, args)` calls Game.spawn(obj.classname, args) for all other users in room

`destroy(obj)` calls obj:destroy() for all other users in room

`sync(obj, vars)` syncs given properties of obj with other users in room

* Ex. `Net.sync(player, {'hspeed', 'score', 'y'})`

`on(event, fn)` add a callback for a net event

* `ready` connect() was successful
* `fail` connect() failed
* `connect (clientid)` another player has connected
* `disconnect (clientid)` another player has disconnected
* `data (data, info)` from Net.send(data)
  * `data` data that was sent
  * `info` { timestamp, room, clientid }

`ip()` returns ip address 

# net object (added with net=true, Net.sync, Net.spawn)

## object properties

`net_vars` variables that are synced between clients

`net_spawn_vars` variables that are synced when __Net.spawn__ is used or a when a new player connects 