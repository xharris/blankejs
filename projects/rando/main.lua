--[[
Rando: uno implementation where a number randomly changes every turn
]]

require 'xhh-array'

rando_effect = nil
hand_z = 40

Game{
	plugins = { 'xhh-effect' },
	load = function()
		--rando_effect = Effect("static", "chroma shift")
		State.start('play')		
	end
}

State('play',{
		enter = function()
			newDeck()
			draw(4)
		end,
		update = function(dt)
			local hand = hands[Net.id]
			
			-- draw my hand
			if hand then
				local hand_w = (card_w/4) * hand.length
				local start_x = (Game.width - hand_w)/2
				local incr_x = hand_w / hand.length
				hand:forEach(function(card, c)
					card.x = start_x + ((c-1) * incr_x)
					card.y = Game.height - (card_h/3)
					card.z = hand_z + c
					card.angle = 20
					card.style = 'hand'
				end)
			end
		end,
		leave = function()
			
		end
})