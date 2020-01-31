--[[
Rando: uno implementation where a number randomly changes every turn
]]

require 'xhh-array'

Game{
	load = function()
		State.start('play')		
	end
}

State('play',{
		enter = function()
			newDeck()
			draw(4)
			draw(4,'gary')
			discard(hands[Net.id][1])
			randomize()--table.random(table.keys(hands)))
		end,
		leave = function()
			
		end
})