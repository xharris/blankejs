--[[
	Game {
	plugins = { 'xhh-array', 'xhh-badword', 'xhh-vector', 'xhh-effect' },
	--plugins = {'xhh-effect'},
	auto_require = false,
	scripts = { 'scripts/path.lua' },
	initial_state = 'path',
	-- effect = { 'chroma shift' }, -- TODO get this to work
	background_color = 'white',
	load = function() 
		Image.animation(
			'blue_robot.png',
			{ { rows=1, cols=8, frames={ '2-5' } } }
		)
				
		-- Game.effect = { 'static' }
	end,
	--background_color="white",
}
]]
local W,H
local testCanvas


local sqrt, sin, cos, min, max = math.sqrt, math.sin, math.cos, math.min, math.max
local pi = math.pi
local r1, r2 =  0          ,  1.0
local g1, g2 = -sqrt( 3 )/2, -0.5
local b1, b2 =  sqrt( 3 )/2, -0.5


--[[--
  @param h a real number between 0 and 2*pi
  @param s a real number between 0 and 1
  @param v a real number between 0 and 1
]]
local function HSVToRGB( h, s, v, a )
  h=h+pi/2--because the r vector is up
  local r, g, b = 1, 1, 1
  local h1, h2 = cos( h ), sin( h )
  
  --hue
  r = h1*r1 + h2*r2
  g = h1*g1 + h2*g2
  b = h1*b1 + h2*b2
  --saturation
  r = r + (1-r)*s
  g = g + (1-g)*s
  b = b + (1-b)*s
  
  r,g,b = r*v, g*v, b*v
  
  return r*255, g*255, b*255, (a or 1) * 255
end


--[[
for i = 0, 360, 15 do
  print( i, HSVToRGB( pi*2*(i/360)))
end
--os.exit( true, true )
--]]



local function drawHSVTest( canvas, v )
  local _c = love.graphics.getCanvas()
  love.graphics.setCanvas( canvas )
  local W,H = canvas:getDimensions()
  print( W,H )
  local setColor, points = love.graphics.setColor, love.graphics.points
  for x = 0, W do
    for y = 0, H do
      setColor( HSVToRGB( 2*pi*(x/W), y/H, v ) )
      points(x,y)
    end
  end
  love.graphics.setCanvas( _c )
end


function love.load()
  love.resize()
end


function love.resize()
  W,H = love.graphics.getDimensions()
  testCanvas  = love.graphics.newCanvas( W,H )
  drawHSVTest( testCanvas, 1 )
end


function love.draw()
  love.graphics.setColor( 255, 255, 255, 255 )
  love.graphics.setBlendMode( "alpha", "premultiplied" )
  love.graphics.draw( testCanvas )
end