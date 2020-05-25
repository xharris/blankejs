BORDER_COLOR = Draw.hexToRgb("#6a717b")

local window_list = {}

UI = {
  titlebar_height = 16,
	update = function(dt)
		local titlebar_focus, bg_focus
    local titlebar_height = UI.titlebar_height
		local check_hover

    for i, win in ipairs(window_list) do
			-- check window drag events
			if Input.pressed('mouse') then
				-- grabbing titlebar
				if mouse_x > win.x and mouse_x < win.x+win.width and mouse_y > win.y and mouse_y < win.y + titlebar_height then
					titlebar_focus = win
				end
				-- touching anywhere in window
				if mouse_x > win.x and mouse_x < win.x + win.width and mouse_y > win.y and mouse_y < win.y + win.height + titlebar_height then
					-- put this window on top of others
					if bg_focus == nil or not bg_focus.is_top then
						bg_focus = win
					end
				end
			end
			if Input.released('mouse') then
				win.dragging = false
			end
			-- hovering in general
			if not check_hover or win.z > check_hover.z then
				if mouse_x > win.x and mouse_x < win.x+win.width and mouse_y > win.y and mouse_y < win.y + win.height + titlebar_height then
					check_hover = win
				end
			end
		end

    for i, win in ipairs(window_list) do
			if win == check_hover then
				win.hovering = true
			else
				win.hovering = false
			end
		end

		if titlebar_focus and titlebar_focus == bg_focus then
			-- grabbing titlebar
			titlebar_focus.dragging = { x = mouse_x-titlebar_focus.x, y = mouse_y-titlebar_focus.y }
			-- put this window on top of others
			UI.focus(titlebar_focus)

		elseif bg_focus then
			-- put this window on top of others
			UI.focus(bg_focus)

		end
	end,
	focus = function(window)
		if not window.is_top then
      table.filter(window_list, function(win)
				return win ~= window
			end)
      table.insert(window_list, window)
      for i, win in ipairs(window_list) do
				win.z = i
				win.is_top = false
			end
			Game.sortDrawables()
			window.is_top = true
		end
	end
}

UI.Window = Entity("UI.Window",{
	background_color="black",
	spawn = function(self)
		self.cam_id = "UI.Window-"..self.uuid
    print('new window',self.cam_id)
		self.cam = Camera(self.cam_id, { auto_use=false, width=self.width, height=self.height })
		self.canvas = Canvas{auto_draw=false}
		self.dragging = false

		self.elements = {}

    table.insert(window_list, self)
		UI.focus(self)
	end,
	add = function(self, obj)
		obj:remDrawable()
		obj.window = self
    table.insert(self.elements, 1, obj)
	end,
	update = function(self, dt)
    local titlebar_height = UI.titlebar_height
		-- dragging window
		if self.dragging then
			self.x = mouse_x - self.dragging.x
			self.y = mouse_y - self.dragging.y
		end

		-- window bounds
		if self.x < 0 then self.x = 0 end
		if self.x + self.width > Game.width then self.x = Game.width - self.width end
		if self.y < 0 then self.y = 0 end
		if self.y + self.height + titlebar_height > Game.height then self.y = Game.height - self.height - titlebar_height end

		if self.update_fn then
			self:update_fn(dt)
		end

		-- window offset for child objects
		self.offx = self.x
		self.offy = self.y + titlebar_height
	end,
	draw = function(self)
    local titlebar_height = UI.titlebar_height

		self.canvas:drawTo(function()
		Camera.attach(self.cam_id)
		Draw.crop(0,0,self.width,self.height)
			Draw.clear()
			-- window background
			--if not self.use_cam then Draw.reset() end
			Draw{
				{'push'},
				{'reset'},
				{'color', self.background_color},
				{'rect','fill',0,0,Game.width,Game.height},
				{'color'},
				{'pop'}
			}
			-- draw contents
			Draw.push()
			if not self.use_cam then Draw.reset() end -- draw at global positions
      for _, e in ipairs(self.elements) do
				e:draw()
			end
			if self.draw_fn then
				self:draw_fn(self.x, self.y + titlebar_height)
			end
			Draw.pop()

		Camera.detach()
		end)

		self.canvas.x = self.x
		self.canvas.y = self.y + titlebar_height
		self.canvas:draw()

		Draw.lineJoin("bevel")

		-- window border
		Draw.color(BORDER_COLOR)
		Draw.lineWidth(2)
		Draw.rect("line",0,0,self.width,self.height+titlebar_height,2)

		-- title bar
		if self.is_top then
			Draw.color("blue")
		else
			Draw.color("gray")
		end
		Draw.rect("line",0,0,self.width,titlebar_height,2)
		Draw.rect("fill",0,0,self.width,titlebar_height,2)

		-- window title
		if self.title then
			Draw.color('white')
			Draw.print(self.title,2,1)
		end
	end
})


Signal.on("Game.start", function()
  window_list = {}

  Signal.on('update', function(dt)
    UI.update(dt)
  end)
end)
