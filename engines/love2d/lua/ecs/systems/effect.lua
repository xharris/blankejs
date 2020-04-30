local disable_image_batching
local get_shader

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

local safe_names = {}
local tryEffect = function(name)
  assert(library[name], "Effect :'"..name.."' not found")
end

local generateShader = function(names, override)
  local full_name = table.join(names, '+')
  if shaders[full_name] and not override then 
      return shaders[full_name]
  end
  shaders[full_name] = { vars = {}, unused_vars = {} }

  local shader_code = ''
  local var_code = ''
  local eff_call_code = ''
  local pos_call_code = ''

  for _,name in ipairs(names) do 
      local safe_name = name:replace(' ','_')
      safe_names[name] = safe_name
      local info = library[name]
      tryEffect(name)
      assert(info.code.solo == nil or (info.code.solo and #names == 1), "Effect '"..name.."' is a solo effect. It cannot be combine with other shaders.")
      shaders[full_name].vars[name] = copy(info.opt.vars)
      shaders[full_name].unused_vars[name] = copy(info.opt.unused_vars)
      local solo_shader

      if info.code.solo then
          solo_shader = true 
          shader_code = info.code.solo
      else
          -- add pixel shader code
          if info.code.position then
              shader_code = shader_code .. info.code.position .. '\n\n'
              pos_call_code = pos_call_code .. "vertex_position = "..safe_name:replace(' ','_').."_shader_position(transform_projection, vertex_position);\n";
          end 
          -- add vertex shader code
          if info.code.effect then
              shader_code = shader_code .. info.code.effect .. '\n\n'
              eff_call_code = eff_call_code .. "color = "..safe_name:replace(' ','_').."_shader_effect(color, texture, texture_coords, screen_coords);\n";
          end 
          -- add vars
          if info.code.vars then 
              var_code = var_code..'\n'.. info.code.vars .. '\n'
          end 
      end
  end
  -- put it all together in one shader
  if not solo_shader then 
      shader_code = "// BEGIN "..full_name.."\n"..var_code..'\n'..helper_fns..'\n'..shader_code..[[   

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
  ]]..pos_call_code..[[
  return transform_projection * vertex_position;
}
#endif


#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  ]]..eff_call_code..[[
  return color;
}
#endif
// END ]]..full_name
  end

  for old, new in pairs(love_replacements) do
      shader_code = shader_code:replace(old, new, true)
  end

  shaders[full_name].name = full_name
  shaders[full_name].solo = solo_shader
  -- shaders[full_name].code = shader_code
  shaders[full_name].shader = love.graphics.newShader(shader_code)

  return shaders[full_name]
end

get_shader = function(obj, names) 
  obj.shader_info = generateShader(names)
  table.update(obj.vars, obj.shader_info.vars)

  disable_image_batching(obj)
  -- track enabling/disabling
  for _, name in ipairs(obj.names) do 
    if obj.enabled[name] == nil then 
      obj.enabled[name] = true
    end
  end
  for i, name in ipairs(obj.names) do 
    track(obj.enabled, name)
  end
end

disable_image_batching = function(obj)
  obj = get_entity(obj)
  -- shaders dont work well with spritebatch
  if obj.effect.canvas.is_setup and obj.image and obj.image.batch then 
    obj.image.batch = false
  end
end

Component('effect', { enabled={}, vars={}, time=0 })

System{
  component='effect',
  requires=EcsUtil.require_draw_components(),
  add = function(obj) 
    local obj_entity = get_entity(obj)
    -- parse initial shader names
    local names = {}
    if type(obj) == 'table' then 
      for _, name in ipairs(obj) do 
        table.insert(names, name)
      end
    end
    obj.names = obj.names or names
    obj.canvas = Canvas{auto_clear={1,1,1,0}, auto_draw=false}
    get_shader(obj, obj.names)
    
    obj_entity.renderer = EffectRenderer()
  end,

  update = function(obj, dt)
    -- did the enabled shaders change?
    local remake_shader = {}
    for i, name in ipairs(obj.names) do 
      if changed(obj.enabled, name) or obj.enabled[name] == nil then 
        if obj.enabled[name] ~= false then
          tryEffect(name)
          table.insert(remake_shader, name)
        end
      end
    end
    -- remake it!
    if remake_shader then 
      if #remake_shader > 0 then 
        get_shader(obj, remake_shader)
      else
        -- no shaders active
        obj.canvas:release()
      end
    end
    
    disable_image_batching(obj)
    
    local shader_info = obj.shader_info
    local shader_object = shader_info.shader
    local vars
    for _, name in ipairs(obj.names) do 
      if obj.enabled[name] then 
        vars = obj.vars[name]
        -- update built in shader vars
        vars.time = vars.time + dt
        vars.tex_size = {Game.width, Game.height}

        for k, v in pairs(vars) do
          -- update user shader vars
          if not obj.shader_info.unused_vars[name][k] then 
            local safe_name = (safe_names[name] or '').."_"..k
            shader_object:send(safe_name, v)
          end
        end
      end
    end
  end
}

EffectRenderer = RenderSystem{
  render = function(obj, fn_draw)
    Effect.apply(obj, fn_draw)
  end
}

Effect = {
    new = function(name, in_opt)
        local safe_name = name:replace(' ','_')
        local opt = { use_canvas=true, vars={}, unused_vars={}, integers={}, code=nil, effect='', vertex='' }
        table.update(opt, in_opt)
        
        -- mandatory vars
        if not opt.vars['tex_size'] then
            opt.vars['tex_size'] = {Game.width, Game.height}
        end
        if not opt.vars['time'] then
            opt.vars['time'] = 0
        end
        code_solo = nil
        code_effect = nil
        code_position = nil
        -- create var string
        var_str = ""
        for key, val in pairs(opt.vars) do
            -- unused vars?
            if not string.contains(opt.code or (opt.effect..' '..opt.vertex), key) then
                opt.unused_vars[key] = true
            end
            if not opt.code then  -- not a solo shader, prepend shader name
                key = safe_name.."_"..key
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

        if opt.code then
            code_solo = var_str.."\n"..helper_fns.."\n"..opt.code
        
        else
            if opt.vertex:len() > 1 then 
                code_position = [[
vec4 ]]..safe_name..[[_shader_position(mat4 transform_projection, vec4 vertex_position) {
]]..opt.vertex..[[
    return transform_projection * vertex_position;
}
]]
            end
                
            if opt.effect:len() > 1 then 
                code_effect = [[
vec4 ]]..safe_name..[[_shader_effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
    vec4 pixel = Texel(texture, texture_coords);
]]..opt.effect..[[
    return pixel * color;
}
]]
            end
        end

        for key, val in pairs(opt.vars) do
            if code_effect then 
                code_effect = code_effect:replace(key,safe_name.."_"..key,true)
            end
            if code_position then 
                code_position = code_position:replace(key,safe_name.."_"..key,true)
            end
        end

        library[name] = {
            opt = copy(opt),
            code = {
                vars = var_str,
                effect = code_effect,
                position = code_position,
                solo = code_solo
            }
        }

    end;
    info = function(name) return library[name] end;
    apply = function(obj, fn)
        local used = false
        local effect_obj = obj.effect
        
        if effect_obj == nil or not Feature('effect') then
            fn()
            return true
        end 
        
        for _, name in ipairs(effect_obj.names) do 
            if effect_obj.enabled[name] then 
              used = true
              
              if library[name] and library[name].opt.draw then 
                  library[name].opt.draw(effect_obj.shader_info.vars[name])
              end
            end
        end
        
        local canvas = obj.canvas or effect_obj.canvas
        if used then 
            local last_shader = love.graphics.getShader()
            
            -- canvas.blendmode = self.blendmode
            canvas:setup()
            canvas.auto_clear = {1,1,1,0}
            canvas:drawTo(function()
                love.graphics.setShader()
                fn()
            end)
            
            love.graphics.setShader(effect_obj.shader_info.shader)
            canvas:draw()
            love.graphics.setShader(last_shader)
        else 
          fn()
        end
    end;
}
