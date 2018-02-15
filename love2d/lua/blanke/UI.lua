local btn_click = Input('mouse.1')
btn_click.can_repeat = false

UI = Class{
	margin = 4,
	element_width = 100,
	element_height = 16,

	_color = {
		window_bg = Draw.white,
		window_outline = Draw.gray,
		element_bg = Draw.gray,
		text = Draw.white
	},

	color_names = {'red','purple','blue','green','yellow','orange','brown','black'},
	colors = {
		red={{255,205,210,255},{244,67,54,255},{183,28,28,255}},
		purple={{225,190,231,255},{156,39,176,255},{74,20,140,255}},
		blue={{179,229,252,255},{3,169,244,255},{1,87,155,255}},
		green={{200,230,201,255},{76,175,80,255},{27,94,32,255}},
		yellow={{255,249,196,255},{255,235,59,255},{245,127,23,255}},
		orange={{255,204,188,255},{255,87,34,255},{191,54,12,255}},
		brown={{215,204,200,255},{121,85,72,255},{62,39,35,255}},
		black={{245,245,245,255},{158,158,158,255},{33,33,33,255}}
	},

	_element_stack = {},
	_return_stack = {},
	_temp = {},
	_window = nil,
	next_element_x = 0,
	next_element_y = 0,

	color = function(name, value)
		if not value then return UI._color[name]
		else UI._color[name] = value end
	end,

	update = function()
		function mouseInElement(btn_dimensions)
			return 
				mouse_x > btn_dimensions[1] and
				mouse_x < btn_dimensions[1] + btn_dimensions[3] and
				mouse_y > btn_dimensions[2] and
				mouse_y < btn_dimensions[2] + btn_dimensions[4]
		end

		if btn_click() then
			for e, el in ipairs(UI._element_stack) do
				if el.type == 'button' then
					if mouseInElement(el.button) then
						UI._return_stack[el.label] = true
					end
				end

				if el.type == 'spinbox' then
					if mouseInElement(el.btn_left) then

						local sel_index = el.index - 1
						if sel_index < 1 then sel_index = #el.options end
						if sel_index > #el.options then sel_index = 1 end

						UI._return_stack[el.label] = el.options[sel_index]
					end

					if mouseInElement(el.btn_right) then

						local sel_index = el.index + 1
						if sel_index < 1 then sel_index = #el.options end
						if sel_index > #el.options then sel_index = 1 end

						UI._return_stack[el.label] = el.options[sel_index]
					end
				end

				if el.type == 'colorpicker' then
					if mouseInElement(el.btn_left) then
						local index = table.find(UI.color_names, el.color)
						index = index - 1
						if index < 1 then
							index = #UI.color_names
						end
						UI._temp[el.label] = UI.color_names[index]
					end

					if mouseInElement(el.btn_right) then
						local index = table.find(UI.color_names, el.color)
						index = index + 1
						if index > #UI.color_names then
							index = 1
						end
						UI._temp[el.label] = UI.color_names[index]
					end

					if mouseInElement(el.btn_color1) then
						UI._return_stack[el.label] = {el.color, UI.colors[el.color][1]}
					end
					if mouseInElement(el.btn_color2) then
						UI._return_stack[el.label] = {el.color, UI.colors[el.color][2]}
					end
					if mouseInElement(el.btn_color3) then
						UI._return_stack[el.label] = {el.color, UI.colors[el.color][3]}
					end
				end
			end
		end
		UI._element_stack = {}
	end,

	window = function(label, x, y, width, height)
		UI._window = {label, x, y, width, height}
		UI.next_element_x = x
		UI.next_element_y = y
		
		Draw.setColor(UI.color('window_bg'))
		Draw.rect('fill',x,y,width,height)
		Draw.setColor(UI.color('window_outline'))
		Draw.rect('line', x+2,y+2,width-4,height-4)
	end,

	spinbox = function(label, options, selected)
		if not UI._window then return false end

		love.graphics.setFont(BlankE.font)

		local win_title, win_x, win_y, win_w, win_h = unpack(UI._window)
		local selection_index = table.find(options, selected)
		if selection_index < 1 or selection_index > #options then
			selection_index = 1
		end

		local element_x = UI.next_element_x+UI.margin
		local element_y = UI.next_element_y+UI.margin
		local element_w = win_w-(UI.margin*2)
		local element_h = UI.element_height+UI.margin

		-- container
		Draw.setColor(UI.color('element_bg'))
		Draw.rect('fill',element_x,element_y,element_w,element_h)

		-- text
		Draw.setColor(UI.color('text'))
		Draw.textf(selected, element_x, element_y+4, element_w, "center")

		-- arrows
		Draw.setColor(UI.color('window_bg'))
		Draw.setLineWidth(2)
		local el_offset_y = (element_h / 2) - (10/2)
		
		Draw.line(
			element_x + 10, element_y + el_offset_y,
			element_x + 5, element_y+5 + el_offset_y,
			element_x + 10, element_y+10 + el_offset_y
		)
		Draw.line(
			(element_x + element_w - 15)  + 5, element_y + el_offset_y,
			(element_x + element_w - 15)  + 10, element_y+5 + el_offset_y,
			(element_x + element_w - 15)  + 5, element_y+10 + el_offset_y
		)

		table.insert(UI._element_stack, {
			type='spinbox',
			label=label,
			btn_left={element_x, element_y, 15, element_h},
			btn_right={element_x+element_w-15, element_y, 15, element_h},
			options=options,
			index=selection_index
		})

		UI.next_element_y = UI.next_element_y + element_h + UI.margin

		-- value has previously changed?
		if UI._return_stack[label] then
			local ret_val = UI._return_stack[label]
			UI._return_stack[label] = nil
			return true, ret_val
		end
		return false, selected
	end,

	button = function(label)
		if not UI._window then return false end

		local win_title, win_x, win_y, win_w, win_h = unpack(UI._window)
		local element_x = UI.next_element_x+UI.margin
		local element_y = UI.next_element_y+UI.margin
		local element_w = win_w-(UI.margin*2)
		local element_h = UI.element_height+UI.margin

		-- container
		Draw.setColor(UI.color('element_bg'))
		Draw.rect('fill',element_x,element_y,element_w,element_h)

		-- text
		Draw.setColor(UI.color('text'))
		Draw.textf(label, element_x, element_y+4, element_w, "center")

		table.insert(UI._element_stack, {
			type='button',
			label=label,
			button={element_x,element_y,element_w,element_h}
		})

		UI.next_element_y = UI.next_element_y + element_h + UI.margin

		-- button was clicked?
		if UI._return_stack[label] then
			local ret_val = UI._return_stack[label]
			UI._return_stack[label] = nil
			return true
		end
		return false
	end,

	colorpicker = function(label, color)
		if not UI._window then return false end

		local win_title, win_x, win_y, win_w, win_h = unpack(UI._window)
		local element_x = UI.next_element_x+UI.margin
		local element_y = UI.next_element_y+UI.margin
		local element_w = win_w-(UI.margin*2)
		local element_h = UI.element_height+UI.margin

		-- container
		Draw.setColor(UI.color('element_bg'))
		Draw.rect('fill',element_x,element_y,element_w,element_h)

		-- color choices
		color = ifndef(UI._temp[label], color)
		UI._temp[label] = color

		Draw.setColor(UI.color('text'))
		local color_box_w = element_h
		local color_index = 1
		for x = element_x, element_x+(color_box_w*2), color_box_w do
			Draw.setColor(UI.colors[color][color_index])
			Draw.rect('fill', x+15, element_y, color_box_w, element_h)
			color_index = color_index + 1
		end

		-- arrows
		Draw.setColor(UI.color('window_bg'))
		Draw.setLineWidth(2)
		local el_offset_y = (element_h / 2) - (10/2)
		
		Draw.line(
			element_x + 10, element_y + el_offset_y,
			element_x + 5, element_y+5 + el_offset_y,
			element_x + 10, element_y+10 + el_offset_y
		)
		Draw.line(
			(element_x + element_w - 15)  + 5, element_y + el_offset_y,
			(element_x + element_w - 15)  + 10, element_y+5 + el_offset_y,
			(element_x + element_w - 15)  + 5, element_y+10 + el_offset_y
		)

		table.insert(UI._element_stack, {
			type='colorpicker',
			label=label,
			color=color,
			btn_left={element_x, element_y, 15, element_h},
			btn_right={element_x+element_w-15, element_y, 15, element_h},
			btn_color1={element_x+15,element_y, color_box_w, element_h},
			btn_color2={element_x+15+(color_box_w),element_y, color_box_w, element_h},
			btn_color3={element_x+15+(color_box_w*2),element_y, color_box_w, element_h}
		})

		UI.next_element_y = UI.next_element_y + element_h + UI.margin
		
		-- button was clicked?
		if UI._return_stack[label] then
			local ret_val = UI._return_stack[label]
			UI._return_stack[label] = nil
			return true, ret_val
		end
		return false
	end
}

return UI