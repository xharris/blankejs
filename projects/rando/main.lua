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
			play(hands[Net.id][1])
			randomize(table.random(table.keys(hands)))
		end,
		leave = function()
			
		end
})