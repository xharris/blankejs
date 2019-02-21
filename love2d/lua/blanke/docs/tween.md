
Tween(var, value, [duration, fn_type, onFinish])
-- var: the object that requires changing or initial value
-- value: target object properties or value
-- duration: seconds
-- fn_type: linear, quadratic [in, out, in/out], circular in

-- instance methods
setValue(value)
addFunction(name, fn)
setFunction(name)
play()
destroy()

-- instance callbacks
onFinish()
