## Save

When the game loads, `Save.load()` is automatically called. When the game is closed, `Save.save()` is called.

```
Save.update{
    level = 4,
    user = {
        name = "Bender",
        stats = {
            strength = 100,
            agility = 100,
            intelligence = 50
        }
    }
}

-- erase player stat
Save.update{
    user = {
        stats = {
            agility = nil
        }
    }
}
-- OR --
Save.remove("user","stats","agility")
```

# class properties

`data = {}`

# class methods

`dir()` returns save directory

`update{data}` update save data

`remove(key1, key2, ...)` remove a value from the save data

`load()` loads saved data into `Save.data`

`save()` saves `Save.data` to file
