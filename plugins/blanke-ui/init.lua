BORDER_COLOR = {Draw.parseColor("#6a717b")}

local window_list = {}
local last_win_x, last_win_y = 0, 0

local mouse_inside = function(obj,x,y,w,h)
  local offx, offy = 0, 0
  local in_win = true

  if obj then
    if obj.window then
      offx, offy = obj.window.offx, obj.window.offy
    end

    in_win = (not obj.window) or obj.window.hovering
  end

  local mx, my = mouse_x - offx, mouse_y - offy


  return in_win and (mx > x and mx < x + w and my > y and my < y + h)
end

Signal.on("Game.restart", function()
    last_win_x, last_win_y = 0, 0
    window_list = {}
end)

Signal.on("Game.start", function()
    Input.set({
        ["UI.mouse"] = {'mouse1'},
        ["UI.mouse_rpt"] = {'mouse1'},
    },{ no_repeat={'UI.mouse'} })
end)

Signal.on('update', function(dt)
    UI.update(dt)
end)

UI = {
    titlebar_height = 16,
    scroll_width = 20,
    list_margin = 4,
  update = function(dt)
    local titlebar_focus, bg_focus
        local titlebar_height = UI.titlebar_height
    local check_hover

        for i, win in ipairs(window_list) do
        -- check window drag events
        if Input.pressed('UI.mouse') then
          -- grabbing titlebar
          if mouse_inside(win, win.x, win.y, win.width, titlebar_height) then
                    titlebar_focus = win
          end
          -- touching anywhere in window
          if mouse_inside(win, win.x, win.y, win.width, win.height + titlebar_height) then
            -- put this window on top of others
            if bg_focus == nil or not bg_focus.is_top then
              bg_focus = win
            end
          end
        end
        if Input.released('UI.mouse') then
          win.dragging = false
        end
        -- hovering in general
        if not check_hover or win.z > check_hover.z then
          if mouse_inside(win, win.x, win.y, win.width, win.height + titlebar_height) then
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
    self.cam = Camera(self.cam_id, { auto_use=false, width=self.width, height=self.height })
    -- self.canvas = {auto_draw=false}
    self.dragging = false

    if not self.x then self.x = last_win_x + UI.titlebar_height end
    if not self.y then self.y = last_win_y + UI.titlebar_height end

    last_win_x, last_win_y = self.x, self.y

    self.elements = {}

    table.insert(window_list, self)
    UI.focus(self)
  end,
  add = function(self, ...)
    for _, obj in ipairs({...}) do
    obj:remDrawable()
    obj.window = self
        table.insert(self.elements, 1, obj)
    end
  end,
  clear = function(self)
    for _, el in ipairs(self.elements) do
        el:destroy()
    end
  end,
  ondestroy = function(self)
    self:clear()
  end,
  focus = function(self)
    UI.focus(self)
  end,
  mouse_inside = function(self, ...)
    return UI.mouse_inside(self, ...)
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

    -- window offset for child objects
    self.offx = self.x
    self.offy = self.y + titlebar_height
  end,
  draw = function(self)
    local titlebar_height = UI.titlebar_height

    Camera.attach(self.cam_id)
    Draw.crop(self.x,self.y + titlebar_height,self.width,self.height)
    Draw.clear()
    -- window background
    --if not self.use_cam then Draw.reset() end
    Draw{
      {'push'},
      {'reset'},
      {'color', self.background_color},
      {'rect','fill',self.x,self.y,self.width,self.height + titlebar_height},
      {'color'},
      {'pop'}
    }
    -- draw contents
    Draw.push()
    if not self.use_cam then Draw.reset() end -- draw at global positions

    Draw.translate(self.x, self.y + titlebar_height)
    iterate(self.elements, function(e)
      if e.destroyed then return true end 
      e:draw()
    end)
    
    if self.draw_fn then
      self:draw_fn(self.x, self.y + titlebar_height)
    end
    Draw.pop()

    Camera.detach()

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

UI.List = Entity("UI.List",{
  scroll_y = 0,
  scroll_max = 0,
  items={},
  entered={}, -- keep track of which item mouse is hovering over
  disabled={},
  color={}, -- { item = color }
  add = function(self, item, opt)
    opt = opt or {}
    table.insert(self.items, item)

    if opt.disabled then self.disabled[item] = true end
  end,
  addItems = function(self, list, key)
    for _, item in ipairs(list) do
      if key then
        table.insert(self.items, item[key])
      else
        table.insert(self.items, item)
      end
    end
  end,
  update = function(self, dt)
        local margin = UI.list_margin

    self.scroll_max = Math.max(0, ((#self.items) * Draw.textHeight()) - self.height)

    local x, y, w, h
        local limit = Game.width
    if self.window then
            limit = self.window.width - (margin * 2)
    end

    x, y = margin, - self.scroll_y + margin
    for i, item in ipairs(self.items) do
      w, h = self.width - (margin * 2) - UI.scroll_width, Draw.textHeight(item, limit)

      if not self.disabled[item] and mouse_inside(self, x, y, w, h) then
        -- mouse entered
        if not self.entered[item] then
          self.entered[item] = true
          self:emit("enter", item)
        end

        -- clicking an item in list
        if Input.pressed('UI.mouse') then
          self:emit("click", item, i)
        end
      elseif self.entered[item] then
        self.entered[item] = false
        self:emit("leave", item)
      end

      y = y + h
    end

    local offx, offy = 0, 0
    if self.window then
      offx, offy = self.window.offx, self.window.offy
    end

    -- controlling the scrollbar with mouse
    local mx, my = mouse_x - offx, mouse_y - offy
    if Input.pressed('UI.mouse_rpt') then
      if mx > self.width - (UI.scroll_width + margin) then
        self.scroll_y = Math.prel(0, self.height, my) * self.scroll_max
      end
    end

    -- controlling the scrollbar with wheel
    local wheel = Input('wheel')
    if wheel and wheel.y ~= 0 then
      self.scroll_y = self.scroll_y - 100 * wheel.y * dt
    end

    self.scroll_y = Math.clamp(self.scroll_y, 0, self.scroll_max)
  end,
  draw = function(self, d)
        local margin = UI.list_margin
    --Draw.crop(self.x + margin,self.y + margin,self.width - (margin*2),self.height + UI.titlebar_height - (margin*2))

    local colors
    local x, y, w, h
        local limit = Game.width
        if self.window then
            limit = self.window.width - (margin * 2)
        end

    -- draw items
    x, y = margin, - self.scroll_y + margin
    for i, item in ipairs(self.items) do
      w, h = self.width - (margin * 2) - UI.scroll_width, Draw.textHeight(item, limit)

      if not self.disabled[item] and (mouse_inside(self, x, y, w, h) or self.selected == item) then
                colors = {'blue','white'}
      else
        colors = {'white','black'}
        if self.color[item] then
          colors = self.color[item]
        end
      end

      Draw{
        {'color',colors[1]},
        {'rect',"fill",x,y,w,h},
        {'color',colors[2]},
        {'print',item,x+2,y+1,limit},
        {'color'}
      }

      y = y + h
    end

    -- draw scrollbar
    local line_x = self.width - ((UI.scroll_width + margin)/2)
    local line_y = margin * 2
    local radius = 6
    Draw{
      {'color','gray', 0.25},
      {'line',line_x, line_y, line_x, line_y + self.height}
    }
    if (#self.items) * Draw.textHeight() > self.height then
      Draw{
        {'color', 'gray'},
        {'circle','fill', line_x, line_y + Math.lerp(0,self.height,self.scroll_y/self.scroll_max), radius}
      }
    end
  end
})

UI.Button = Entity("UI.Button",{
    text = "",
    border_width = 3,
    spawn = function(self)
        self:refreshSize()
    end,
    refreshSize = function(self)
        local w, h = Draw.textSize(self.text)
        self.width = w + self.border_width
        self.height = h + self.border_width
        return self.width, self.height
    end,
    update = function(self, dt)
        local w, h = self:refreshSize()
        local border_w = self.border_width

        if mouse_inside(self, self.x, self.y, w + border_w, h + border_w) and Input.pressed('UI.mouse') then
            self:emit('click', self.text, self)
        end
    end,
    draw = function(self)
        local w, h = self.width, self.height
        local border_w = self.border_width

        local mouse_in = mouse_inside(self, self.x, self.y, w + border_w, h + border_w)

        Draw{
            {'color',mouse_in and 'black' or 'gray'},
            {'rect','fill',0,0,w + border_w, h + border_w, 2},
            {'color','white'},
            {'print',self.text,border_w,border_w}
        }
    end
})

UI.Label = Entity("UI.Label",{
    text = "",
    fg_color = "black",
    bg_color = "transparent",
    spawn = function(self)
        self:refreshSize()
    end,
    refreshSize = function(self)
        local w, h = Draw.textSize(self.text)
        self.width = w
        self.height = h
        return self.width, self.height
    end,
    draw = function(self)
        local w, h = self:refreshSize()
        local limit = Game.width
        if self.window then
            limit = self.window.width
        end

        Draw{
            {'color',self.bg_color},
            {'rect','fill',0,0,w,h},
            {'color',self.fg_color},
            {'print',self.text,0,0,limit}
        }
    end
})

UI.TextInput = Entity("UI.TextInput",{
  text = "",
  update = function(self, dt)

  end
})
