--[[
Rando: uno implementation where a number randomly changes every turn
]]

require 'xhh-array'

hand_z = 40

Game{
	background_color = 'black2',
	plugins = { 'xhh-effect' },
	load = function()
		State.start('play')		
	end
}

local bob
State('play',{
		enter = function()
			newDeck()
			draw(8)
			bob = Game.spawn("card_text", {image="reverse", angle=45})
		end,
		update = function(dt)
			local hand = hands[Net.id]
			-- draw my hand
			if hand then
				local focus_card
				local hand_w = (card_w/4) * hand.length
				local start_x = (Game.width - hand_w)/2
				local incr_x = hand_w / hand.length
				hand:forEach(function(card, c)
					-- draw the cards in an arc at bottom of screen
					card.x = math.floor(start_x + ((c-1) * incr_x) + card.width / 2)
					card.y = math.floor(Game.height/2 - (card.width/4) - (math.sin(Math.lerp(0,math.pi,(c-1)/(hand.length-1))) * 15))
					card.z = hand_z + c
					card.angle = 0--Math.lerp(-10,10,(c-1)/(hand.length-1))
					card.style = 'hand'
					card.visible = true
					if Math.pointInShape(card.rect, mouse_x, mouse_y) then
						focus_card = card
					end
				end)
				if focus_card then 
					focus_card.z = hand_z + hand.length + 1
					focus_card.focused = true
				end
			end
		end,
		draw = function()
			local hand = hands[Net.id]
			if hand then
				hand:forEach(function(card, c)
					card:drawRect()
				end)
			end
			bob:draw()
			Draw{
				{'color','white'},
				{'font','CaviarDreams_Bold.ttf',18},
				{'print','1234567890',20,20}
				}
		end,
		leave = function()
			
		end
})