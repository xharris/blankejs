Game {
	plugins = { 'xhh-array', 'xhh-badword', 'xhh-vector', 'xhh-effect' },
	load = function() 
		State.start('math')
	end
}

Entity("bob",{
	update = function(self, dt)