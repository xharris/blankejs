--[[
Rando: uno implementation where a number randomly changes every turn
]]

require 'xhh-array'

hand_z = 40

Game{
	plugins = { 'xhh-effect' },
	load = function()
		State.start('play')		
	end
}

State('play',{
		enter = function()
			newDeck()
			draw(8)
		end,
		update = function(dt)
			local hand = hands[Net.id]
			
			-- draw my hand
			if hand then
				local hand_w = (card_w/4) * hand.length
				local start_x = (Game.width - hand_w)/2
				local incr_x = hand_w / hand.length
				hand:forEach(function(card, c)
					-- draw the cards in an arc at bottom of screen
					card.x = math.floor(start_x + ((c-1) * incr_x) + card.width / 2)
					card.y = math.floor(Game.height - (card.width/4) - (math.sin(Math.lerp(0,math.pi,(c-1)/(hand.length-1))) * 15))
					card.z = hand_z + c
					card.angle = 0 --Math.lerp(-10,10,(c-1)/(hand.length-1))
					card.style = 'hand'
					card.visible = true
					card:drawRect()
				end)
			end
		end,
		leave = function()
			
		end
})