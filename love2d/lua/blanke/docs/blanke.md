--- INITIALIZE BLANKE ENGINE

-- in main.lua:
require('blanke.Blanke')

function love.load()
	Asset.add('scripts/')

	BlankE.init(mainState)
end

--- AVOID SLOPPY CODE
-- try not to use global vars to communicate between objects
-- find object-oriented solutions
-- keep Net callbacks outside of class code

--- THINGS TO KNOW

-- 1) do NOT create objects outside of functions
-- WRONG:
main_camera = View()
function state0:enter()

end

-- 2) some classes are persistent by default:
Bezier
Tween

-- BETTER:
main_camera = nil
function state0:enter()
	main_camera = View()
end

-- 3) destroying an object does not remove references to it
-- 
my_entity:destroy()
my_entity = nil 		-- GOOD: no longer referencing it

-- properties
scale_mode = 'scale'		-- can be: stretch, scale, center
draw_debug = false			-- automatically draw Debug.log()

-- methods
init(first_state) -- first_state: can be string or object
drawOutsideWindow()	-- can be overridden to make custom drawings outside of game frame
