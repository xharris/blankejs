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
local sin, cos, rad, deg, abs, min, max = math.sin, math.cos, math.rad, math.deg, math.abs, math.min, math.max

local changed = function(ent, key)
  if ent['_last_'..key] ~= ent[key] then 
    ent['_last_'..key] = ent[key]
    return true
  end 
  return false
end
local reset = function(ent, key)
  ent['_last_'..key] = ent[key]
end 

--CANVAS
Canvas = Entity("Blanke.Canvas", {
  auto_clear = true,
  drawable = true,
  blendmode = {"alpha"},
  debug_color = 'blue',
  added = function(ent)
    if ent.size[1] <= 0 then ent.size[1] = Game.width end 
    if ent.size[2] <= 0 then ent.size[2] = Game.height end
    
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
CanvasStack = Stack(function()
    return Canvas{draw=false}
end)

--IMAGE: image / animation
Image = nil
do
  local animations = {}

  local update_size = function(image)
    local ent = image.parent or image
    -- image size 
    if not (image and image.skip_size) then 
      ent.size = {
        image.drawable:getWidth(),
        image.drawable:getHeight()
      }
    end
  end

  local setup_image = function(ent)
    local info = animations[ent.name]

    ent.quads = nil
    ent.frame_count = 0

    if not info then 
      info = { file=ent.name }
    else 
      -- animated
      ent.speed = info.speed or 1
      ent.t, ent.frame_index, ent.frame_len = 0, 1,  info.durations[1] or info.duration
      ent.frame_count = #info.quads
      ent.quads = info.quads
    end

    ent.drawable = Cache.image(info.file)

    update_size(ent)
    return ent
  end

  Image = Entity("Blanke.Image", {
    name = nil,
    debug_color = 'blue',
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

  Image.get = function(name)
    if type(name) == 'table' then 
      return setup_image(name)
    else
      return setup_image{name=name}
    end
  end 

  System(All("image"), {
    added = function(ent, args)
      local type_image = type(ent.image)
      if type_image == 'string' then 
        ent.image = Image{
          name=ent.image,
          parent=ent
        }
      elseif type_image == 'table' then
        ent.image.parent = ent 
        ent.image = Image(ent.image)
      end
    end
  })
end

--ENTITY: gravity, velocity
System(All("pos", "vel", Not("hitbox")), {
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
                          Render(canv_final.value, true)
                      end
                  end)

                  -- draw to final canvas with shader
                  canv_final.value:renderTo(function()
                      love.graphics.setShader(self.shader_info[name].shader)
                      Render(canv_internal.value, true)
                  end)
              end
          end

          -- draw final resulting canvas
          Render(canv_final.value, true)

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

--SPRITEBATCH
SpriteBatch = Entity("Blanke.SpriteBatch", {
    added = function(ent)
        ent.drawable = Cache.spritebatch(ent.file, ent.z)
    end,
    set = function(ent, in_quad, in_tform, id)
        in_quad = in_quad or { 0, 0, 1, 1 }
        in_tform = in_tform or { 0, 0 }

        -- get quad
        local quad = Cache.quad(ent.file, unpack(in_quad))
        if id then 
            ent.drawable:set(id, quad, unpack(in_tform))
            return id
        else 
            return ent.drawable:add(quad, unpack(in_tform))
        end
    end,
    remove = function(ent, id)
        return ent.drawable:set(id, 0, 0, 0, 0, 0) 
    end
})

--MAP
Map = nil
do
  local getObjInfo = function(uuid, is_name)
    if Game.config.scene and Game.config.scene.objects then
      if is_name then
        for uuid, info in pairs(Game.config.scene.objects) do
          if info.name == uuid then
            return info
          end
        end
      else
        return Game.config.scene.objects[uuid]
      end
    end
  end 


  Map = Entity("Blanke.Map", {
    added = function(ent)
      ent.batches = {} -- { layer: SpriteBatch }
      ent.hb_list = {}
      ent.entity_info = {} -- { obj_name: { info_list... } }
      ent.entities = {} -- { layer: { entities... } }
      ent.paths = {} -- { obj_name: { layer_name:{ Paths... } } }
      ent.layer_order = {}
    end,
    update = function(ent, dt)

    end,
    addTile = function(self,file,x,y,tx,ty,tw,th,layer)
      local options = Map.config
      layer = layer or '_'
      local tile_info = { x=x, y=y, width=tw, height=th, tag=hb_name, quad={ tx, ty, tw, th }, transform={ x, y } }

      -- add tile to spritebatch
      -- print('need',file,unpack(tile_info.quad))
      if not self.batches[layer] then 
          self.batches[layer] = {}
      end
      local sb = self.batches[layer][file]
      if not sb then sb = SpriteBatch{file=file, parent=self, z=self:getLayerZ(layer)} end
      self.batches[layer][file] = sb
      local id = sb:set(tile_info.quad, tile_info.transform)
      tile_info.id = id

      -- hitbox
      local hb_name = nil
      if options.tile_hitbox then hb_name = options.tile_hitbox[FS.removeExt(FS.basename(file))] end
      local body = nil
      if hb_name then
        tile_info.tag = hb_name
        if options.use_physics then
          hb_key = hb_name..'.'..tw..'.'..th
          if not Physics.getBodyConfig(hb_key) then
            Physics.body(hb_key, {
              shapes = {
                {
                  type = 'rect',
                  width = tw,
                  height = th,
                  offx = tw/2,
                  offy = th/2
                }
              }
            })
          end
          local body = Physics.body(hb_key)
          body:setPosition(x,y)
          tile_info.body = body
        end
      end
      if not options.use_physics and tile_info.tag then
          Hitbox.add(tile_info)
          table.insert(self.hb_list, tile_info)
      end
    end,
    getLayerZ = function(self, l_name)
      for i, name in ipairs(self.layer_order) do
          if name == l_name then return i end
      end
      return 0
    end,
    addHitbox = function(self,tag,dims,color)
      local new_hb = {
          hitbox = dims,
          tag = tag,
          debug_color = color,
      }
      table.insert(self.hb_list, new_hb)
      Hitbox.add(new_hb)
    end,
    getEntityInfo = function(self, name)
      return self.entity_info[name] or {}
    end;
    _spawnEntity = function(self, ent_name, opt)
        local ent = Entity.spawn(ent_name, opt)
        if ent then
            opt.layer = opt.layer or "_"
            return self:addEntity(ent, opt.layer)
        end
    end;
    spawnEntity = function(self, ent_name, x, y, layer)
      layer = layer or "_"
      obj_info = getObjInfo(ent_name, true)
      if obj_info then
          obj_info.pos = {x, y}
          obj_info.z = self:getLayerZ(layer)
          obj_info.layer = layer or "_"
          return self:_spawnEntity(ent_name, obj_info)
      end
    end,
    addEntity = function(self, ent, layer_name)
      layer_name = layer_name or "_"
      if not self.entities[layer_name] then self.entities[layer_name] = {} end
      table.insert(self.entities[layer_name], ent)
      ent.parent=self
      sort(self.entities[layer_name], 'z', 0)
      return ent
    end
  })
  Map.config = {}
  Map.load = function(name, opt)
      local data = love.filesystem.read(Game.res('map',name))
      assert(data,"Error loading map '"..name.."'")
      local new_map = Map(opt)
      data = json.decode(data)
      new_map.data = data
      local layer_name = {}
      -- get layer names
      local store_layer_order = false

      if #new_map.layer_order == 0 then
          new_map.layer_order = {}
          store_layer_order = true
      end
      for i = #data.layers, 1, -1 do
          local info = data.layers[i]
          layer_name[info.uuid] = info.name
          if store_layer_order then
              table.insert(new_map.layer_order, info.name)
          end
      end
      -- place tiles
      for _,img_info in ipairs(data.images) do
          for l_uuid, coord_list in pairs(img_info.coords) do
              l_name = layer_name[l_uuid]
              for _,c in ipairs(coord_list) do
                  new_map:addTile(img_info.path,c[1],c[2],c[3],c[4],c[5],c[6],l_name)
              end
          end
      end
      -- make paths
      for obj_uuid, info in pairs(data.paths) do
        local obj_info = getObjInfo(obj_uuid)
        local obj_name = obj_info.name
        for layer_uuid, info in pairs(info) do
          local layer_name = layer_name[layer_uuid]
          local new_path = Path()
          -- add nodes
          local tag
          for node_key, info in pairs(info.node) do
            if type(info[3]) == "string" then tag = info[3] else tag = nil end
            new_path:addNode{x=info[1], y=info[2], tag=tag}
          end
          -- add edges
          for node1, edge_info in pairs(info.graph) do
            for node2, tag in pairs(edge_info) do
              local _, node1_hash = new_path:getNode{x=info.node[node1][1], y=info.node[node1][2], tag=info.node[node1][3]}
              local _, node2_hash = new_path:getNode{x=info.node[node2][1], y=info.node[node2][2], tag=info.node[node2][3]}
              if type(tag) ~= "string" then tag = nil end
              new_path:addEdge{a=node1_hash, b=node2_hash, tag=tag}
            end
          end

          if not new_map.paths[obj_name] then
            new_map.paths[obj_name] = {}
          end
          if not new_map.paths[obj_name][layer_name] then
            new_map.paths[obj_name][layer_name] = {}
          end
          -- get color
          if obj_info then
            new_path.color = { Draw.parseColor(obj_info.color) }
          end
          table.insert(new_map.paths[obj_name][layer_name], new_path)
        end
      end

      -- spawn entities/hitboxes
      for obj_uuid, info in pairs(data.objects) do
        local obj_info = getObjInfo(obj_uuid)
        if obj_info then
          for l_uuid, coord_list in pairs(info) do
            for _,c in ipairs(coord_list) do
              local hb_color = { Draw.parseColor(obj_info.color) }
              hb_color[4] = 0.3
              -- spawn entity
              if Entity.exists(obj_info.name) then
                local new_entity = new_map:_spawnEntity(obj_info.name, {
                  map_tag=c[1], pos={c[2], c[3]}, z=new_map:getLayerZ(layer_name[l_uuid]), layer=layer_name[l_uuid], points=copy(c),
                  map_size={obj_info.size[1], obj_info.size[2]}, debug_color=hb_color
                })

              -- spawn hitbox
              else
                  new_map:addHitbox(table.join({obj_info.name, c[1]},'.'), table.slice(c,2), hb_color)
              end
              -- add info to entity_info table
              if not new_map.entity_info[obj_info.name] then new_map.entity_info[obj_info.name] = {} end
              table.insert(new_map.entity_info[obj_info.name], {
                map_tag=c[1], x=c[2], y=c[3], z=new_map:getLayerZ(layer_name[l_uuid]), layer=layer_name[l_uuid], points=copy(c),
                width=obj_info.size[1], height=obj_info.size[2], color=hb_color
              })
            end
          end
        end
      end

    return new_map
  end
end 

--PHYSICS: (entity?)
Physics = nil
do
    local world_config = {}
    local body_config = {}
    local joint_config = {}
    local worlds = {}

    local setProps = function(obj, src, props)
        for _,p in ipairs(props) do
            if src[p] ~= nil then obj['set'..string.capitalize(p)](obj,src[p]) end
        end
    end

    --PHYSICS.BODYHELPER
    local BodyHelper = class {
        init = function(self, body)
            self.body = body
            self.body:setUserData(helper)
            self.gravx, self.gravy = 0, 0
            self.grav_added = false
        end;
        update = function(self, dt)
            if self.grav_added then
                self.body:applyForce(self.gravx,self.gravy)
            end
        end;
        setGravity = function(self, angle, dist)
            if dist > 0 then
                self.gravx, self.gravy = Math.getXY(angle, dist)
                self.body:setGravityScale(0)
                if not self.grav_added then
                    table.insert(Physics.custom_grav_helpers, self)
                    self.grav_added = true
                end
            end
        end;
        setPosition = function(self, x, y)
            self.body:setPosition(x,y)
        end
    }

    Physics = {
        custom_grav_helpers = {};
        debug = false;
        init = function(self)
            self.is_physics = true
        end;
        update = function(dt)
            for name, world in pairs(worlds) do
                local config = world_config[name]
                world:update(dt,8*config.step_rate,3*config.step_rate)
            end
            for _,helper in ipairs(Physics.custom_grav_helpers) do
                helper:update(dt)
            end
        end;
        getWorldConfig = function(name) return world_config[name] end;
        world = function(name, opt)
            if type(name) == 'table' then
                opt = name
                name = '_default'
            end
            name = name or '_default'
            if opt or not world_config[name] then
                world_config[name] = opt or {}
                table.defaults(world_config[name], {
                    gravity = 0,
                    gravity_direction = 90,
                    sleep = true,
                    step_rate = 1
                })
            end
            if not worlds[name] then
                worlds[name] = love.physics.newWorld()
            end
            local w = worlds[name]
            local c = world_config[name]
            -- set properties
            w:setGravity(Math.getXY(c.gravity_direction, c.gravity))
            w:setSleepingAllowed(c.sleep)
            return worlds[name]
        end;
        getJointConfig = function(name) return joint_config[name] end;
        joint = function(name, opt) -- TODO: finish joints
            if not worlds['_default'] then Physics.world('_default', {}) end
            if opt then
                joint_config[name] = opt
            end
        end;
        getBodyConfig = function(name) return body_config[name] end;
        body = function(name, opt)
            if not worlds['_default'] then Physics.world('_default', {}) end
            if opt then
                body_config[name] = opt
                table.defaults(body_config[name], {
                    x = 0,
                    y = 0,
                    angularDamping = 0,
                    gravity = 0,
                    gravity_direction = 0,
                    type = 'static',
                    fixedRotation = false,
                    bullet = false,
                    inertia = 0,
                    linearDamping = 0,
                    shapes = {}
                })
                return
            end
            assert(body_config[name], "Physics config missing for '#{name}'")
            local c = body_config[name]
            if not c.world then c.world = '_default' end
            assert(worlds[c.world], "Physics world '#{c.world}' config missing (for body '#{name}')")
            -- create the body
            local body = love.physics.newBody(worlds[c.world], c.x, c.y, c.type)
            local helper = BodyHelper(body)
            -- set props
            setProps(body, c, {'angularDamping','fixedRotation','bullet','inertia','linearDamping','mass'})
            helper:setGravity(c.gravity, c.gravity_direction)
            local shapes = {}
            for _,s in ipairs(c.shapes) do
                local shape = nil
                table.defaults(s, {
                    density = 0
                })
                switch(s.type,{
                    rect = function()
                        table.defaults(s, {
                            width = 1,
                            height = 1,
                            offx = 0,
                            offy = 0,
                            angle = 0
                        })
                        shape = love.physics.newRectangleShape(c.x+s.offx,c.y+s.offy,s.width,s.height,s.angle)
                    end,
                    circle = function()
                        table.defaults(s, {
                            offx = 0,
                            offy = 0,
                            radius = 1
                        })
                        shape = love.physics.newCircleShape(c.x+s.offx,c.y+s.offy,s.radius)
                    end,
                    polygon = function()
                        table.defaults(s, {
                            points = {}
                        })
                        assert(#s.points >= 6, "Physics polygon must have 3 or more vertices (for body '"..name.."')")
                        shape = love.physics.newPolygonShape(s.points)
                    end,
                    chain = function()
                        table.defaults(s, {
                            loop = false,
                            points = {}
                        })
                        assert(#s.points >= 4, "Physics polygon must have 2 or more vertices (for body '"..name.."')")
                        shape = love.physics.newChainShape(s.loop, s.points)
                    end,
                    edge = function()
                        table.defaults(s, {
                            points = {}
                        })
                        assert(#s.points >= 4, "Physics polygon must have 2 or more vertices (for body '"..name.."')")
                        shape = love.physics.newEdgeShape(unpack(s.points))
                    end
                })
                if shape then
                    fix = love.physics.newFixture(body,shape,s.density)
                    setProps(fix, s, {'friction','restitution','sensor','groupIndex'})
                    table.insert(shapes, shape)
                end
            end
            return body, shapes
        end;
        setGravity = function(body, angle, dist)
            local helper = body:getUserData()
            helper:setGravity(angle, dist)
        end;
        draw = function(body, _type)
            for _, fixture in pairs(body:getFixtures()) do
                shape = fixture:getShape()
                if shape:typeOf("CircleShape") then
                    local x, y = body:getWorldPoints(shape:getPoint())
                    Draw.circle(_type or 'fill', floor(x), floor(y), shape:getRadius())
                elseif shape:typeOf("PolygonShape") then
                    local points = {body:getWorldPoints(shape:getPoints())}
                    for i,p in ipairs(points) do points[i] = floor(p) end
                    Draw.poly(_type or 'fill', points)
                else
                    local points = {body:getWorldPoints(shape:getPoints())}
                    for i,p in ipairs(points) do points[i] = floor(p) end
                    Draw.line(body:getWorldPoints(shape:getPoints()))
                end
            end
        end;
        drawDebug = function(world_name)
            world_name = world_name or '_default'
            if Physics.debug then
                world = worlds[world_name]
                for _, body in pairs(world:getBodies()) do
                    Draw.color(1,0,0,.8)
                    Physics.draw(body,'line')
                    Draw.color(1,0,0,.5)
                    Physics.draw(body)
                end
                Draw.color()
            end
        end;
    }

    System(One("body", "fixture"),{
      added = function(ent)
        ent.physics = Physics.body(ent.physics)
      end,
      removed = function(ent)
        ent.physics:destroy()
      end 
    })
end

--HITBOX: pos, vel, size, hitbox
Hitbox = nil
do
  local bump = blanke_require('bump')
  local world = bump.newWorld(40)
  local new_boxes = true
  local hb_items = {}
  
  Hitbox = {
    debug = false,
    draw = function() 
      if Hitbox.debug then
        local x,y,w,h
        if new_boxes then
            new_boxes = false
            hb_items, hb_len = world:getItems()
        end
        for _,i in ipairs(hb_items) do
            if i.hitbox and not i.destroyed then
                x,y,w,h = world:getRect(i)
                Draw.color(i.debug_color or {1,0,0,0.9})
                Draw.rect('line',x,y,w,h)
                Draw.color(i.debug_color or {1,0,0,0.25})
                Draw.rect('fill',x,y,w,h)
            end
        end
        Draw.color()
      end
    end
  }

  local get_dims = function(ent)
    local ax, ay, w, h = getAlign(ent)
    return 
      ent.pos[1], 
      ent.pos[2],
      max(w, 1), 
      max(h, 1)
  end 

  System(All("hitbox", "pos", "vel", "size"),{
    order = 'post',
    added = function(ent)
      local type_hbox = type(ent.hitbox)
      if type_hbox ~= 'table' then 
        if type_hbox == 'string' then 
          ent.hitbox = { reaction=ent.hitbox }
        else 
          ent.hitbox = {}
        end
      end 
      world:add(ent, get_dims(ent,0,0))
      new_boxes = true
    end,
    update = function(ent, dt)
      local filter_result
      local filter = function(obj_ent, other_ent)
          local _obj = obj_ent.hitbox
          local other = other_ent.hitbox

          local ret = _obj.reaction or Hitbox.default_reaction
          if other.reactions and other.reactions[obj_ent.tag] then ret = other.reactions[obj_ent.tag] else
              if other.reaction then ret = other.reaction end
          end
          if _obj.reactions and _obj.reactions[other_ent.tag] then ret = _obj.reactions[other_ent.tag] else
              if _obj.reaction then ret = _obj.reaction end
          end
          if _obj.filter then ret = _obj:filter(other_ent) end

          filter_result = ret

          if ret == 'static' then 
            ret = 'slide'
          end 
          return ret
      end

      local ax, ay = getAlign(ent)

      local next_x = (ent.pos[1]) + ent.vel[1] * dt
      local next_y = (ent.pos[2]) + ent.vel[2] * dt
      local new_x, new_y, cols, len = world:move(ent, next_x, next_y, filter)

      if ent.destroyed then return end 
      --if filter_result ~= 'static' then 
        ent.pos[1] = new_x
        ent.pos[2] = new_y
      --end 
      
      local swap = function(t, key1, key2)
        local temp = t[key1]
        t[key1] = t[key2]
        t[key2] = temp
      end
      if len > 0 then
        local hspeed, vspeed, bounciness, nx, ny
        for i=1,len do
            hspeed, vspeed, bounciness = ent.vel[1], ent.vel[2], ent.bounciness or 1
            nx, ny = cols[i].normal.x, cols[i].normal.y
            -- change velocity by collision normal
            if cols[i].bounce then
              if hspeed and ((nx < 0 and hspeed > 0) or (nx > 0 and hspeed < 0)) then 
                ent.vel[1] = -ent.vel[1] * bounciness
              end
              if vspeed and ((ny < 0 and vspeed > 0) or (ny > 0 and vspeed < 0)) then 
                ent.vel[2] = -ent.vel[2] * bounciness
              end
            end
            
            if not ent or ent.destroyed then return end
            if ent.collision then ent:collision(cols[i]) end 

            local info = cols[i]
            local other = info.other
            swap(info, 'item', 'other')
            swap(info, 'itemRect', 'otherRect')
            if other and not other.destroyed and other.collision then other:collision(info) end
        end
      end
      -- entity size changed, update in world
      if changed(ent.scaled_size, 1) or changed(ent.scaled_size, 2) then
        world:update(ent, get_dims(ent))
      end 
    end,
    removed = function(ent)
      world:remove(ent)
      new_boxes = true
    end
  })
end

--BACKGROUND
Background = nil
BFGround = nil
do
  local bg_list = {}
  local fg_list = {}

  local quad
  local add = function(opt)
    opt = opt or {}
    if opt.file then
      opt.image = Cache.get('Image', Game.res('image',opt.file), function(key)
        return love.graphics.newImage(key)
      end)
      opt.x = 0
      opt.y = 0
      opt.scale = 1
      opt.width = opt.image:getWidth()
      opt.height = opt.image:getHeight()
      if not quad then 
        quad = love.graphics.newQuad(0,0,1,1,1,1)
      end 
    end
    return opt
  end

  local update = function(list, dt)
    iterate(list, function(t)
      if t.remove == true then
        return true
      end

      if t.size == "cover" then
        if t.width < t.height then
          t.scale = Game.width / t.width
        else
          t.scale = Game.height / t.height
        end
        t.image:setWrap('clamp','clamp')
        t.x = (Game.width - (t.width * t.scale))/2
        t.y = (Game.height - (t.height * t.scale))/2
      else 
        t.image:setWrap('repeat','repeat')
      end 
    end)
  end

  local draw = function(list)
    local lg_draw = love.graphics.draw
    for _, t in ipairs(list) do
      if t.image then
        if t.size == 'cover' then 
          lg_draw(t.image,0,0,0,t.scale,t.scale)
        else
          quad:setViewport(-t.x,-t.y,Game.width,Game.height,t.width,t.height)
          lg_draw(t.image,quad,0,0,0,t.scale,t.scale)
        end
      end
    end
  end

  BFGround = {
    update = function(dt)
      update(bg_list, dt)
      update(fg_list, dt)
    end;
  }

  Background = callable {
    __call = function(self, opt)
      local t = add(opt)
      table.insert(bg_list, opt)
      return t
    end;
    draw = function()
      draw(bg_list)
    end
  }
  Foreground = callable {
    __call = function(self, opt)
      local t = add(opt)
      table.insert(fg_list, opt)
      return t
    end;
    draw = function()
      draw(fg_list)
    end
  }
end

--PARTICLES
Particles = nil 
do 
    local methods = {
        offset = 'Offset',
        rate = 'EmissionRate',
        area = 'EmissionArea',
        colors = 'Colors',
        max = 'BufferSize',
        lifetime = 'ParticleLifetime',
        linear_accel = 'LinearAcceleration',
        linear_damp = 'LinearDamping',
        rad_accel = 'RadialAcceleration',
        relative = 'RelativeRotation',
        direction = 'Direction',
        rotation = 'Rotation',
        size_vary = 'SizeVariation',
        sizes = 'Sizes',
        speed = 'Speed',
        spin = 'Spin',
        spin_vary = 'SpinVariation',
        spread = 'Spread',
        tan_accel = 'TangentialAcceleration',
        position = 'Position',
        insert = 'InsertMode'
    }

    local update_source = function(ent)
      local source = ent.source 
      local type_src = type(source)

      -- get texture and quad from image
      if type_src == 'string' then 
        ent.source = Image.get{parent=ent, name=source}
        --ent.size = ent.source.size
        source = ent.source
      end

      if not source.drawable then return end 
        
      -- create/edit the particle system
      if not ent.psystem then 
        ent.psystem = love.graphics.newParticleSystem(source.drawable)
      else
        ent.psystem:setTexture(source.drawable)
      end
    end 

    Particles = Entity("Blanke.Particles",{
      frame = 0,
      added = function(ent, args)
        if args and #args > 0 then 
          if type(args[1]) == 'table' then 
            ent.source = args[1].source
          else 
            ent.source = args[1]
          end 
        end 
        assert(ent.source, "Particles instance needs source")

        update_source(ent)
        reset(ent, 'source')

        -- initial psystem settings
        if ent.psystem then 
          for k, v in pairs(ent) do 
            if methods[k] then
              if type(v) == 'table' then 
                ent.psystem['set'..methods[k]](ent.psystem, unpack(v)) 
              else
                ent.psystem['set'..methods[k]](ent.psystem, v) 
              end
            end
            args[k] = nil
          end
        end

        -- getters/setters
        for k,v in pairs(methods) do 
          ent[k] = function(ent, ...) 
            if ent.psystem then 
              ent.psystem['set'..v](ent.psystem, ...) 
              return ent.psystem['get'..v](ent.psystem)
              end
          end
        end

        ent.drawable = ent.psystem
      end,
      stop = function(self)
        self:rate(0)
      end,
      emit = function(self, n)
        self.psystem:emit(n)
      end,    
      update = function(ent, dt)
        if changed(ent, 'source') then 
          update_source(ent)
        end 
        if changed(ent, 'frame') and ent.source.quads then 
          local f, quads = ent.frame, ent.source.quads
          if f > 0 and f < #quads + 1 then 
            ent.psystem:setQuads(quads[f])
          else 
            ent.psystem:setQuads(quads)
          end
        end 

        if ent.psystem then
          local follow = ent.follow
          if follow then 
            local ax, ay = getAlign(follow)
            ent.scale = follow.scale 
            ent.scalex = follow.scalex 
            ent.scaley = follow.scaley
            ent.align = {ax,ay}
            ent.psystem:setPosition(
              (follow.pos[1] + ax) / follow.scale / follow.scalex,
              (follow.pos[2] + ay) / follow.scale / follow.scaley
            )
          end 
          ent.psystem:update(dt)
        end
      end
    })
end

--NET: needs to be reworked for ecs
--PATH: (entity)
--TIMELINE: (entity)