BlankE.addState("PlayState")

local player
local asteroids = Group()
local tmr_spawn_roid
local tmr_respawn
local can_respawn = false

local fnt_asteroids = Font{name="Hyperspace", size=24}

local eff_death = Effect("static","chroma shift")
local main_view = View()
main_view.x = game_width / 2
main_view.y = game_height / 2

local img_ship = Image("ship")

local score = 0
local lives = 2
local level = 1
local game_over = false

Input.set("respawn", "r")

function PlayState:enter()
	PlayState.background_color = "black"
		
	Net.on('ready',function()
		setupGame()
		startGame()	
	end)
	Net.on('fail',function()
		setupGame()
		startGame()	
	end)
	
	Net.join('localhost',8080)
end

function setupGame()	
	-- player death effect
	eff_death.chroma_shift.radius = 0
	eff_death.static.amount = {0,0}
	Signal.on("player_die",function()
		main_view:shake(10, 0)
			
		-- no more lives
		if lives == 0 then
			game_over = true
		end
			
		lives = lives - 1	
	end)
	Signal.on("death_animation_finish",function()
		player = nil
		if game_over then
			can_respawn = true
		else
			tmr_respawn = Timer(3):after(function()
				can_respawn = true
			end):start()
		end
	end)
	Signal.on("score",function(points)
		score = score + points	
	end)
end

function restartGame()
	asteroids:call("destroy")
	
	Timer(1):after(function()
		startGame()
	end):start()
end

function startGame()
	lives = 3
	score = 0
	game_over = false
	makeField()
end

local starting = false
local tmr_field
function makeField()
	Net.once(function()
		starting = true
		tmr_field = Timer(2):after(function()
			starting = false
			local count = 6 + math.floor(2^(level/2)-1)
			for i = 0, count do
				asteroids:add(Asteroid())
			end		
			if not player and lives == 3 then player = Ship() end
			level = level + 1
			tmr_field = nil
		end):start()
	end)
end

local canv_explosion = Canvas(3,3)
canv_explosion:drawTo(function()
	Draw.setColor("white")
	Draw.setPointSize(3)
	Draw.point(0,0)
end)
local rpt_explosion = Repeater(canv_explosion, {
	direction={0,360},
	speed = 2,
	duration={1,1.5},
	a2=0
})

Signal.on("explosion", function(x,y,small)
	rpt_explosion.x = x
	rpt_explosion.y = y
	if small then 
		rpt_explosion.speed = 1
		rpt_explosion:emit(10)
	else
		rpt_explosion.speed = 2
		rpt_explosion:emit(20)
	end
end)

function PlayState:update(dt)
	if Input("kill").released then
		asteroids:call("destroy")
	end
	
	-- no more asteroids, spawn more
	if not tmr_field and asteroids:size() == 0 then
		makeField()
	end
	
	-- RESPAWN
	if not player and not game_over and can_respawn and Input("respawn").released then 
		player = Ship()
		can_respawn = false
	end
		
	-- NEW GAME
	-- TODO: will be buggy for netplay
	if game_over and (not Net.is_connected or Ship.instances:size() == 0) and can_respawn and Input("respawn").released then
		restartGame()
		can_respawn = false
	end
end

function PlayState:draw()
	Draw.setFont(fnt_asteroids)
	
	
	local function drawStuff()
		Net.draw("Bullet")
		if player then player:draw() end
		Net.draw("Ship")
		asteroids:call("draw")
		Net.draw("Asteroid")
		rpt_explosion:draw()
		
		if game_over then
			if can_respawn then
				Draw.text("game over\npress r to retry", 0, game_height/2 - 50, {align="center"})
			else
				Draw.text("game over", 0, game_height/2 - 50, {align="center"})
			end
		end
	end
	
	main_view:draw(function()
		if player and player.dead then
			eff_death.chroma_shift.radius = main_view.shake_x
			eff_death.static.amount = {main_view.shake_x, 0}
				
			eff_death:draw(function()
				drawStuff()
			end)
		else
			drawStuff()
		end
			
		if starting then 
			Draw.setColor("white")
			Draw.text("get ready", 0, game_height/2 - Draw.font:getHeight()/2, {align="center"})
		end
			
		-- respawn timer
		if tmr_respawn and tmr_respawn.countdown > 0 and not game_over then
			Draw.setColor("white")
			Draw.text("Can respawn in "..tostring(tmr_respawn.countdown).."s..." , 0, game_height/2 - Draw.font:getHeight()/2, {align="center"})
		end
	end)
	
	-- draw score
	Draw.setColor("white")
	Draw.text(score, 50, 50)
	
	-- draw lives left
	for l = 0, lives do
		img_ship:draw(50 + (l * (img_ship.width+2)), 50 + Draw.font:getHeight() + 5)
	end
end

function love.gamepadpressed(joystick, button)
	Debug.log(joystick, button)
end
