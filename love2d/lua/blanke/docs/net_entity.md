Any object added using **Net.addObject(obj)** is given certain methods and properties that are used to sync the object with other clients.

# New properties

```
net_sync_vars[]
num net_owner_id            -- id of the client this object belongs to
num net_uuid                -- id unique to this object on the entire network
bool net_object             -- whether or not this object was sent from another client
bool keep_on_disconnect		-- doesn't disappear from the network when a player leaves
```

## net_sync_vars

Example

`PlayerClass.net_sync_vars = {'x','y','direction','sprite_color'}`

Whenever the variables _x, y, direction,_ and _sprite\_color_ change, their values will be synced with other clients on the network.

# New methods

```
localOnly(fn)           -- will perform fn() only if this object didn't come from another client
netSync('var1', ...)    -- sync given variable names with other clients
onNetAdd()              -- called when added to network with Net.addObject()
onNetUpdate(var, val)   -- whenever a variable is updated, this is called. not all that important.
```