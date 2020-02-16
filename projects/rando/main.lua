--[[
Rando: uno implementation where a number randomly changes every turn
]]

require 'xhh-array'

draw_pile_z = 30
hand_z = 40

Game{
	background_color = 'white2',
	plugins = { 'xhh-effect' },
	effect = { 'chroma shift' },
	load = function()
		State.start('play')		
	end
}

Input({
	action = { 'space' }
})


State('play',{
	enter = function()
		newDeck()
		draw(1, Net.id)
	end,
	update = function(dt)
		if Input.released('action') then
			draw(1, Net.id)
		end
		-- draw the draw pile
		if draw_pile then
			draw_pile:forEach(function(card)
				card.x = Game.width / 2
				card.y = Game.height / 2
				card.z = draw_pile_z
				card.visible = false
				card.style = 'table'
			end)
		end
		local hand = hands[Net.id]
		-- draw my hand
		if hand then
			local focus_card
			local hand_w = (card_w/3) * math.min(hand.length,12)
			local start_x = (Game.width - hand_w)/2
			local incr_x = hand_w / hand.length
			local offx = Math.lerp(0, (mouse_x - (Game.width/2)), hand_w / Game.width)
			hand:forEach(function(card, c)
				-- draw the cards in an arc at bottom of screen
				card.x = Math.lerp(-hand_w/2,hand_w/2, c/hand.length) - (card_w/6) + (Game.width/2) - offx
				if hand.length == 1 then
					card.y = Game.height - (card.width/4)
					card.angle = 0
				else
					card.y = Game.height - (card.width/4) - (math.sin(Math.lerp(0,math.pi,(c-1)/(hand.length-1))) * 15)
					card.angle = Math.lerp(-10,10,(c-1)/math.max(hand.length-1))
				end
				card.z = hand_z + c
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
				--card:drawRect()
			end)
		end
		-- draw the draw pile
		if draw_pile then
			draw_pile:forEach(function(card)
				card:draw()
			end)
		end
	end,
	leave = function()

	end
})