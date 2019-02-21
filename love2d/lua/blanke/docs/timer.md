
-- all time units are in seconds for Timer

-- constructor
Timer([duration])						-- in seconds

-- instance properties
int duration							-- 0s
bool disable_on_all_called				-- true. The timer will stop running once every supplied function is called
int time 								-- elapsed time in seconds
bool running

-- instance methods
before(function, [delay])				-- starts immediately unless delay is supplied
every(function, [interval])				-- interval=1 , function happens on every interal
after(function, [delay])				-- happens after `duration` supplied to constructor with optional delay
start()									-- MUST BE CALLED TO START THE TIMER. DO NOT FORGET THIS OR YOU WILL GO NUTS

-- example: have an 'enemy' entity shoot a laser every 2 seconds
function enemy:shootLaser()
	...
end

function enemy:spawn()
	self.shoot_timer = Timer()
	self.shoot_timer:every(self.shootLaser, 2):start()
end
