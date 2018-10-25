Signal.on('modules_loaded', function()
	Input.set("_UI_primary", "mouse.1")
end)

UIList = Class{
	init = function(self, in_opts)
		self.options = {
			x=0, y=0, rows=1, columns=1, item_width=1, item_height=1, max_width=0, max_height=0, size=0,
			scroll_image=nil,
			fn_drawContainer=function(x,y,w,h)
				Draw.stack(function()
					Draw.reset()
					Draw.setColor("black")
					Draw.rect("line", x, y, w, h)
				end)
			end,
			fn_drawItem=function()

			end
		}
		table.update(self.options, ifndef(in_opts, {}))

		if self.options.max_width == 0 then self.options.max_width = game_width - self.options.x end
		if self.options.max_height == 0 then self.options.max_height = game_height - self.options.y end

		self.scroll_pos = 1

		_addGameObject('uilist', self)
	end,

	setSize = function(self, size)
		self.options.size = size
		return self
	end,

	-- +1 up / -1 down
	scroll = function(self, amt)
		self.scroll_pos = self.scroll_pos + amt
		local upper_limit = self.options.size - math.max(
			math.floor(self.options.max_width / self.options.item_width),
			math.floor(self.options.max_height / self.options.item_height),
			math.floor((self.options.max_width*self.options.max_height) / (self.options.item_width*self.options.item_height))
			) + 1
		if self.scroll_pos > upper_limit then
			self.scroll_pos = upper_limit
		end
		if self.scroll_pos < 1 then
			self.scroll_pos = 1
		end
		return self
	end,

	draw = function(self)
		local options = self.options

		-- container/border
		local scroll_w, scroll_h = 20, 20
		if options.scroll_image then
			scroll_w = options.scroll_image.width
			scroll_h = options.scroll_image.height
		end

		options.fn_drawContainer(options.x, options.y, options.max_width, options.max_height)

		-- draw items
		local x, y = 0, 0
		local w, h = options.item_width, options.item_height
		for i = self.scroll_pos, options.size do
			if i <= options.size and x + w - 1 < options.max_width and y + h - 1 < options.max_height then
				-- local c, r = map2Dindex(i, options.columns)
				w, h = options.fn_drawItem(i, x+self.options.x, y+self.options.y)
				w = ifndef(w, options.item_width)
				h = ifndef(w, options.item_height)

				x = x + w
				if x + w > options.max_width then
					x = 0
					y = y + h
				end
			end
		end

		-- scroll buttons
		local scroll_x, scroll_up_y, scroll_down_y = options.x + options.max_width, options.y, options.y + options.max_height - scroll_h
		if options.scroll_image then

		else
			Draw.stack(function()
				-- scroll up btn
				Draw.setColor("white")
				Draw.rect("fill",scroll_x,scroll_up_y,scroll_w,scroll_h)
				Draw.setColor("black")
				Draw.rect("line",scroll_x,scroll_up_y,scroll_w,scroll_h)

				-- scroll down btn
				Draw.setColor("white")
				Draw.rect("fill",scroll_x,scroll_down_y,scroll_w,scroll_h)
				Draw.setColor("black")
				Draw.rect("line",scroll_x,scroll_down_y,scroll_w,scroll_h)
			end)
		end


		if Input("_UI_primary") == 1 then
			-- scroll up click
			if UI.mouseInside(scroll_x, scroll_up_y, scroll_w, scroll_h) then
				self:scroll(-1)
			end
			-- scroll down click
			if UI.mouseInside(scroll_x, scroll_down_y, scroll_w, scroll_h) then
				self:scroll(1)
			end
		end
	end
}

UI = Class{
	element_dim = {},
	ret_element = {},
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
	mouseInside = function(x,y,w,h)
		return
			mouse_x > x and mouse_x < x + w and
			mouse_y > y and mouse_y < y + h
	end,
	update = function(dt)
		if Input("_UI_mouse1") then
			for name, dims in pairs(UI.element_dim) do
				if UI.mouseInside(dims[1], dims[2], dims[3], dims[4]) then
					UI.ret_element[name] = true
				else
					UI.ret_element[name] = false
				end
			end
		else
			for name, dims in pairs(UI.element_dim) do
				UI.ret_element[name] = false
			end
		end
	end,

	button = function(name, x, y, w, h)
		UI.element_dim[name] = {x,y,x+w,y+h}

		return UI.ret_element[name]
	end,

	list = function(in_opts)
		return UIList(in_opts)
	end
}

oldUI = Class{
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

		if Input("_UI_mouse1") then
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