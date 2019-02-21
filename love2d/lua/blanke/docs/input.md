
Input.set(...)					--[[ constructor containing tracked inputs
Keyboard
	a, b, c, 1, 2, 3...
	!, ", #, &...
	space, backspace, return 		return is also enter
	up, down, left, right
	home, end, pageup, pagedown
	insert, tab, clear
	f1, f2, f3...
	numlock, capslock, scrolllock
	lshift, rshift
	rctrl, lctrl, ralt, lalt
	rgui, lgui						Command/Windows key
	menu						
	application						windows menu key
	mode 							?

Numpad
	kp0, kp1...				number
	kp. kp, kp+
	kpenter

	https://love2d.org/wiki/KeyConstant

Mouse
	mouse.1		left mouse button
	mouse.2		middle mouse button
	mouse.3 	right mouse button

Mouse Wheel
	wheel.up
	wheel.down
	wheel.right	very rare
	wheel.left	also very rare lol

Region			mouse click in a region
	WIP
]]

-- usage
Input.set('move_left', 'a', 'left')		-- call this once
if Input('move_left') then
	hspeed = -125
end

-- class properties
bool key[name].can_repeat	-- true: only true once until the button is released

-- class methods
set(name, ...)				-- set an input
Input(name, ...)			-- checks an input. Can check multiple at a time
