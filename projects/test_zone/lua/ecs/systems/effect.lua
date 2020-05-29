local disable_image_batching
local get_shader
local is_used = {} -- { uuid:t/f }
local used

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
local shaders = {} -- { name = { vars{}, unused_vars{}, love2dShader } }

local tryEffect = function(name)
    assert(library[name], "Effect :'"..name.."' not found")
end

used = function(obj, v)
  if v ~= nil then 
    is_used[obj.uuid] = v
  end
  return is_used[obj.uuid]
end

local _generateShader, generateShader

generateShader = function(names, override)
    if type(names) ~= 'table' then
        names = {names}
    end
    local ret_shaders = {}
    for _, name in ipairs(names) do 
      tryEffect(name)
      local info = library[name]
      if override or not shaders[name] then 
        shader = love.graphics.newShader(info.code)
        shaders[name] = {
            vars = copy(info.opt.vars),
            unused_vars = copy(info.opt.unused_vars),
            shader = shader
        }
      end
      ret_shaders[name] = shaders[name]
    end
    return ret_shaders
end

get_shader = function(obj) 
  local shader_info = generateShader(obj.names)
  
  for name, info in pairs(shader_info) do
    if not obj[name] then obj[name] = {} end
    table.update(obj[name], info.vars)
  end 

  disable_image_batching(obj)
  -- track enabling/disabling
  obj.enabled = {}
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
  if obj.effect.canv_final.is_setup and obj.image and obj.image.batch then 
    obj.image.batch = false
  end
end

Component('effect', { enabled={}, time=0 })

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
    obj.canv_internal = Canvas{auto_draw=false}
    obj.canv_final = Canvas{auto_draw=false}
    get_shader(obj)
    
    obj_entity.renderer = EffectRenderer()
  end,

  update = function(obj, dt)
    -- did the enabled shaders change?
    local remake_shader = false
    local i = 1
    local name
    while i <= #obj.names and not remake_shader do
      name = obj.names[i]
      if changed(obj.enabled, name) or obj.enabled[name] == nil then 
        if obj.enabled[name] ~= false then
          tryEffect(name)
          remake_shader = true
        end
      end
      i = i + 1
    end
    
    -- remake it!
    if remake_shader then 
      get_shader(obj)
    end
    
    disable_image_batching(obj)
    

    used(obj, false)
    local vars
    for _, name in ipairs(obj.names) do 
      local shader_info = shaders[name]

      if obj.enabled[name] then
        used(obj, true) 
        vars = obj[name]
        -- update built in shader vars
        vars.time = vars.time + dt
        vars.tex_size = {Game.width, Game.height}
      end
    end

    if not used(obj) then 
      -- no shaders active
      obj.canv_internal:release()
      obj.canv_final:release()
    else
      obj.canv_internal:setup()
      obj.canv_final:setup()
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
    local opt = { use_canvas=true, vars={}, unused_vars={}, integers={}, code=nil, effect='', vertex='' }
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
  apply = function(obj, fn)
    local effect_obj = obj.effect
    
    if effect_obj == nil or not used(effect_obj) or not Feature('effect') then
        fn()
        return true
    end 
    
    local vars
    for _, name in ipairs(effect_obj.names) do 
      local shader_info = shaders[name]

      if effect_obj.enabled[name] then
        vars = effect_obj[name]

        if library[name] and library[name].opt.update then
          library[name].opt.update(effect_obj[name])
        end

        for k, v in pairs(vars) do
          -- update user shader vars
          if not shader_info.unused_vars[k] then 
            shader_info.shader:send(k, v)
          end
        end
      end
    end
        
    local last_shader = love.graphics.getShader()

    local canv_internal, canv_final = effect_obj.canv_internal, effect_obj.canv_final
            
    canv_internal.auto_clear = {Draw.parseColor(Game.options.background_color, 0)}
    canv_final.auto_clear = {Draw.parseColor(Game.options.background_color, 0)}
    
    for i, name in ipairs(effect_obj.names) do 
      if shaders[name] then
        -- draw without shader first
        canv_internal:drawTo(function()
            love.graphics.setShader()
            if i == 1 then
                -- draw unshaded stuff (first run)
                fn()
            else 
                -- draw previous shader results
                canv_final:draw()
            end
        end)

        -- draw to final canvas with shader
        canv_final:drawTo(function()
            love.graphics.setShader(shaders[name].shader)
            canv_internal:draw()
        end)
      end
    end

    love.graphics.setShader(last_shader)  

    -- draw final resulting canvas
    canv_final:draw()
  end;
}
