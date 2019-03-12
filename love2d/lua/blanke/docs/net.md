# Properties

```
num id 								-- unique client id assigned to the player 
bool is_leader						-- only true for one person on server and moves to another if that person leaves
```

# Methods

```
join([address], [port])				-- address = "localhost", port = 12345
disconnect()

send(data) send object to other clients 
sendPersistent(data) 				-- send data. saved server side and sent to new players that join later

getPopulation()						-- get number of clients connected (including self)
draw([classname])					-- draw objects synced through network, or just a certain class
addObject(obj)						-- add an object to be synced with other clients
```

## Event types

These are called automatically by


-- vvv objects added with 'addObject' are given the follow properties and methods vvv
-- optional obj properties
	ObjClass.net_sync_vars = {}		-- table containing the names of properties to sync ('x','hspeed','walk_speed','sprite_xcsale')

-- this method adds the netSync method to the object
	obj:netSync("x","y","sprite_color") 	-- used to manually sync an object (use wisely)
-- when the object is added to the network an optional function is called
	obj:onNetAdd()
-- every time a variable is updated, this is called. Only called for net_objects, not the client objects
	obj:onNetUpdate(var_name, value)


-- callback methods
Net.on('<callback>', function(...))
ready()
connect(clientid) 		-- different client connects
disconnect(clientid)
receive(data)
event(data)		 		-- called if data.type=='netevent'					
--[[ data will always have the properties:
		clientid: the id of the client that sent the data
		room

	built-in 'netevent':
	- client.connect : info=clientid
	- client.disconnect : info=clientid
	- object.add : another client calls addObject()
	- object.update : getting info about updating an object from anoher client
	- object.sync : sending syncable objects is requested
	- set.leader : a new leader is set
]]
