--[[
  reserved entity properties:
    drawable - love2d object 
    draw - draw automatically or not
    quad - love2d Quad
    renderer - ecs system that renders entity. leave empty to use default
    z 
    uuid
    position, size, angle, scale, scalex, scaley, shear, color, blendmode, align - only set if drawable is set
]]

local changed = function(ent, key)
  if ent['_last_'..key] ~= ent[key] then 
    ent['_last_'..key] = ent[key]
    return true
  end 
  return false
end

-- TODO: turn into a system
local checkAlign = function(ent)
  local align = obj.align

  local ax, ay = obj.alignx or 0, obj.aligny or 0

  if align and align ~= obj._last_align then
      obj._last_align = align

      if align then
          if string.contains(align, 'center') then
              ax = obj.width/2
              ay = obj.height/2
          end
          if string.contains(align,'left') then
              ax = 0
          end
          if string.contains(align, 'right') then
              ax = obj.width
          end
          if string.contains(align, 'top') then
              ay = 0
          end
          if string.contains(align, 'bottom') then
              ay = obj.height
          end
      end
  end

  obj.alignx, obj.aligny = floor(ax), floor(ay)
end

--CANVAS
Canvas = Entity("Blanke.Canvas", {
  is_canvas = true,
  auto_clear = true,
  drawable = true,
  blendmode = {"alpha"}
})
CanvasStack = Stack(function()
    return Canvas{draw=false}
end)
System(All("is_canvas"), {
  added = function(ent)
    if ent.size[1] <= 0 then ent.size[1] = Game.width end 
    if ent.size[2] <= 0 then ent.size[2] = Game.height end
print('add canvas')
    local canvas = love.graphics.newCanvas(unpack(ent.size))
    ent.active = false
    ent.drawable = canvas

    local lg = love.graphics
    ent.renderTo = function(self, fn)
      if fn then 
        lg.push('all')
        self.active = true
        lg.setCanvas{self.drawable}
        if self.auto_clear then lg.clear(self.auto_clear) end
        fn()
        lg.pop()
      end 
    end
    ent.resize = function(self)
      canvas = love.graphics.newCanvas(unpack(self.size))
      ent.drawable = canvas
    end
  end
})

--IMAGE: image / animation
Image = nil
do
  local animations = {}
  Image = Entity("Blanke.Image", {
    is_image = true,
    name = nil
  })
  Image.animation = function(file, anims, all_opt)
    all_opt = all_opt or {}
    local img = getImage(file)
    if not anims then
        anims = {
            { name=FS.removeExt(FS.basename(file)), cols=1, rows=1, frames={1} }
        }
    end
    if #anims == 0 then anims = {{}} end
    for _,anim in ipairs(anims) do
        local o = function(k, default)
            assert(anim[k] or all_opt[k] or default, "'"..k.."' not found for "..file.." -> "..(anim.name or '?'))
            return anim[k] or all_opt[k] or default
        end
        local quads, durations = {}, {}
        local fw, fh = img:getWidth() / o('cols'), img:getHeight() / o('rows')
        local offx, offy = o('offx', 0), o('offy', 0)
        -- calculate frame list
        local frame_list = {}
        local in_frames = o('frames', {'1-'..(o('cols')*o('rows'))})

        assert(not in_frames or type(in_frames) == "table", "Image.animation frames must be in array")
        for _,f in ipairs(in_frames) do
            local f_type = type(f)
            if f_type == 'number' then
                table.insert(frame_list, f)
            elseif f_type == 'string' then
                local a,b = string.match(f,'%s*(%d+)%s*-%s*(%d+)%s*')
                assert(a and b, "Invalid frames for '"..(anim.name or file).."' { "..(a or 'nil')..", "..(b or 'nil').." }")
                for i = a,b do
                    table.insert(frame_list, i)
                end
            end
        end

        -- make quads
        for _,f in ipairs(frame_list) do
            local x,y = Math.indexTo2d(f, o('cols'))
            table.insert(quads, love.graphics.newQuad((x-1)*fw,(y-1)*fh,fw,fh,img:getWidth(),img:getHeight()))
        end
        animations[anim.name or FS.removeExt(FS.basename(file))] = {
            file=file,
            duration=o('duration', 1),
            durations=o('durations', {}),
            quads=quads,
            w=fw, h=fh, frame_size={fw,fh},
            speed=o('speed', 1)
        }
    end
  end;

  local setup_image = function(ent)
    local info = animations[ent.name]
    if not info then 
      info = { file=ent.name }
    else 
      -- animated
      ent.speed = info.speed or 1
      ent.t, ent.frame_index, ent.frame_len = 0, 1,  info.durations[1] or info.duration
      ent.frame_count = #info.quads
    end

    ent.drawable = Cache.get("Image", Game.res('image', info.file), function(key)
      return love.graphics.newImage(key)
    end)
  end

  System(All("is_image"), {
    added = function(ent, args)
      if type(args) == 'table' then
        ent.name = ent.name or args[1] or args.name
      else 
        ent.name = ent.name or ent[1] or args
      end
      setup_image(ent)
    end,
    update = function(ent, dt)
      if changed(ent, 'name') then 
        setup_image(ent)
      end

      local info = animations[ent.name]
      -- animated?
      if info then 
        -- update animation
        ent.t = ent.t + (dt * ent.speed)
        if ent.t > ent.frame_len then
            ent.frame_index = ent.frame_index + 1
            if ent.frame_index > ent.frame_count then ent.frame_index = 1 end
            info = ent.animated
            ent.frame_len = info.durations[tostring(ent.frame_index)] or info.duration
        end
        ent.quad = info.quads[ent.frame_index]
      end 
    end 
  })
end

--ENTITY: gravity, velocity
System(All("pos", "vel"), {
  update = function(ent, dt)
    ent.pos[1] = ent.pos[1] + ent.vel[1] * dt
    ent.pos[2] = ent.pos[2] + ent.vel[2] * dt
  end
})
System(All("gravity", "vel"), {
  added = function(ent)
    table.update(ent, {
      gravity_direction = Math.rad(90)
    })
  end,
  update = function(ent, dt)
    local gravx, gravy = Math.getXY(ent.gravity_direction, ent.gravity)
    ent.vel[1] = ent.vel[1] + gravx
    ent.vel[2] = ent.vel[2] + gravy
  end
})

--EFFECT
Effect = nil
do
    local love_replacements = {
        float = "number",
        int = "number",
        sampler2D = "Image",
        uniform = "extern",
        texture2D = "Texel",
        gl_FragColor = "pixel",
        gl_FragCoord = "screen_coords"
    }
    local helper_fns = [[
/* From glfx.js : https://github.com/evanw/glfx.js */
float random(vec2 scale, vec2 pixelcoord, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(pixelcoord + seed, scale)) * 43758.5453 + seed);
}
float mod(float a, float b) { return - (a / b) * b; }
float getX(float amt) { return amt / love_ScreenSize.x; }
float getY(float amt) { return amt / love_ScreenSize.y; }
float lerp(float a, float b, float t) { return a * (1.0 - t) + b * t; }
]]
    local library = {}
    local shaders = {} -- { 'eff1+eff2' = { shader: Love2dShader } }

    local tryEffect = function(name)
        assert(library[name], "Effect :'"..name.."' not found")
    end

    local _generateShader, generateShader

    generateShader = function(names, override)
        if type(names) ~= 'table' then
            names = {names}
        end
        local ret_shaders = {}
        for _, name in ipairs(names) do
            ret_shaders[name] = _generateShader(name, override)
        end
        return ret_shaders
    end

    local shader_obj = {} -- { name : LoveShader }
    _generateShader = function(name, override)
        tryEffect(name)
        local info = library[name]
        local shader = shader_obj[name] or love.graphics.newShader(info.code)
        if override then
            shader = love.graphics.newShader(info.code)
        end
        shader_obj[name] = shader

        return {
            vars = copy(info.opt.vars),
            unused_vars = copy(info.opt.unused_vars),
            shader = shader,
            auto_vars = info.opt.auto_vars
        }
    end

    local updateShader = function(ent, names)
        if not Feature('effect') then return end
        ent.shader_info = generateShader(names)
        for _, name in ipairs(names) do
            if not ent.vars[name] then ent.vars[name] = {} end
            ent.auto_vars[name] = ent.shader_info[name].auto_vars
            table.update(ent.vars[name], ent.shader_info[name].vars)
        end
    end
      
    Effect = class {
        library = function() return library end;
        new = function(name, in_opt)
            local opt = { use_canvas=true, vars={}, unused_vars={}, integers={}, code=nil, effect='', vertex='', auto_vars=false }
            table.update(opt, in_opt)

            -- mandatory vars
            if not opt.vars['tex_size'] then
                opt.vars['tex_size'] = {Game.width, Game.height}
            end
            if not opt.vars['time'] then
                opt.vars['time'] = 0
            end

            -- create var string
            var_str = ""
            for key, val in pairs(opt.vars) do
                -- unused vars?
                if not string.contains(opt.code or (opt.effect..' '..opt.vertex), key) then
                    opt.unused_vars[key] = true
                end
                -- get var type
                switch(type(val),{
                    table = function()
                        var_str = var_str.."uniform vec"..tostring(#val).." "..key..";\n"
                    end,
                    number = function()
                        if table.hasValue(opt.integers, key) then
                            var_str = var_str.."uniform int "..key..";\n"
                        else
                            var_str = var_str.."uniform float "..key..";\n"
                        end
                    end,
                    string = function()
                        if val == "Image" then
                            var_str = var_str.."uniform Image "..key..";\n"
                        end
                    end
                })
            end

            local code = var_str.."\n"..helper_fns.."\n"
            if opt.code then
                code = code .. opt.code
            else
                code = code .. [[

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    ]]..(opt.position or '')..[[
    return transform_projection * vertex_position;
}
#endif


#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    ]]..(opt.effect or '')..[[
    return pixel * color;
}
#endif
                    ]]
            end

            for old, new in pairs(love_replacements) do
                code = code:replace(old, new, true)
            end

            library[name] = {
                opt = copy(opt),
                code = code
            }

        end;

        info = function(name) return library[name] end;

        init = function(self, ...)
            self.classname = "Blanke.Effect"
            self.names = {...}
            if type(self.names[1]) == 'table' then
                self.names = self.names[1]
            end

            if Feature('effect') then
                self.used = true
                self.vars = {}
                self.disabled = {}
                self.auto_vars = {}
                self:updateShader(self.names)
            end
        end;
        __ = {
            -- eq = function(self, other) return self.shader_info.name == other.shader_info.name end,
            -- tostring = function(self) return self.shader_info.code end
        };
        updateShader = function(self, names)
            if not Feature('effect') then return end
            self.shader_info = generateShader(names)
            for _, name in ipairs(names) do
                if not self.vars[name] then self.vars[name] = {} end
                self.auto_vars[name] = self.shader_info[name].auto_vars
                table.update(self.vars[name], self.shader_info[name].vars)
            end
        end;
        disable = function(self, ...)
            if not Feature('effect') then return end
            local disable_names = {...}
            for _,name in ipairs(disable_names) do
                self.disabled[name] = true
            end
            local new_names = {}
            self.used = false
            for _,name in ipairs(self.names) do
                tryEffect(name)
                if not self.disabled[name] then
                    self.used = true
                    table.insert(new_names, name)
                end
            end
            self:updateShader(new_names)
        end;
        enable = function(self, ...)
            if not Feature('effect') then return end
            local enable_names = {...}
            for _,name in ipairs(enable_names) do
                self.disabled[name] = false
            end
            local new_names = {}
            self.used = false
            for _,name in ipairs(self.names) do
                tryEffect(name)
                if not self.disabled[name] then
                    self.used = true
                    table.insert(new_names, name)
                end
            end
            self:updateShader(new_names)
        end;
        set = function(self,name,k,v)
            if not Feature('effect') then return end
            -- tryEffect(name)
            if not self.disabled[name] then
                if not self.vars[name] then
                    self.vars[name] = {}
                end
                self.vars[name][k] = v
            end
        end;
        send = function(self,name,k,v)
            if not Feature('effect') then return end
            local info = self.shader_info[name]
            if not info.unused_vars[k] then
                tryEffect(name)
                if info.shader:hasUniform(k) then
                    info.shader:send(k,v)
                end
            end
        end;
        update = function(self,dt)
          if not Feature('effect') then return end
          local vars

          for _,name in ipairs(self.names) do
              if not self.disabled[name] then
                  vars = self.vars[name]
                  vars.time = vars.time + dt
                  vars.tex_size = {Game.width,Game.height}

                  if self.auto_vars[name] then
                      vars.inputSize = {Game.width,Game.height}
                      vars.outputSize = {Game.width,Game.height}
                      vars.textureSize = {Game.width,Game.height}
                  end
                  -- send all the vars
                  for k,v in pairs(vars) do
                      self:send(name, k, v)
                  end

                  if library[name] and library[name].opt.update then
                      library[name].opt.update(self.vars[name])
                  end
              end
          end
        end;
        active = 0;
        --@static
        isActive = function()
            return Effect.active > 0
        end;
        draw = function(self, fn)
          if not self.used or not Feature('effect') then
              fn()
              return
          end

          Effect.active = Effect.active + 1

          local last_shader = love.graphics.getShader()
          local last_blend = love.graphics.getBlendMode()

          local canv_internal, canv_final = CanvasStack:new(), CanvasStack:new()

          canv_internal.value.auto_clear = {Draw.parseColor(Game.options.background_color, 0)}
          canv_final.value.auto_clear = {Draw.parseColor(Game.options.background_color, 0)}

          for i, name in ipairs(self.names) do
              if not self.disabled[name] then
                  -- draw without shader first
                  canv_internal.value:renderTo(function()
                      love.graphics.setShader()
                      if i == 1 then
                          -- draw unshaded stuff (first run)
                          fn()
                      else
                          -- draw previous shader results
                          Render(canv_final.value)
                      end
                  end)

                  -- draw to final canvas with shader
                  canv_final.value:renderTo(function()
                      love.graphics.setShader(self.shader_info[name].shader)
                      Render(canv_internal.value)
                  end)
              end
          end

          -- draw final resulting canvas
          Render(canv_final.value)

          love.graphics.setShader(last_shader)
          love.graphics.setBlendMode(last_blend)

          CanvasStack:release(canv_internal)
          CanvasStack:release(canv_final)

          Effect.active = Effect.active - 1
      end;
    }
end

System(All("effect"),{
    added = function(ent)
        ent.effect = Effect(unpack(ent.effect))
    end,
    update = function(ent, dt)
        ent.effect:update(dt)
    end
})

--MAP: (entity)
--PHYSICS: (entity?)
--HITBOX: position, size, hitbox
Hitbox = {
  debug = false
}
--NET: needs to be reworked for ecs
--PATH: (entity)
--TIMELINE: (entity)
--BACKGROUND
--PARTICLES