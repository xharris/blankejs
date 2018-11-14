--[[
completely working effects:
 - chroma shift : angle(rad), radius
 - crt : lineSize(vec2) opacity, scanlines(bool), distortion, inputGamma, outputGamma
 - 
]]
local _effects = {}
Effect = Class{
    _mouse_offx = 0,
    _mouse_offy = 0,
    init = function (self, name)
        self._shader = nil
        self.effect_data = nil
        self.name = name
        self.canvas = Canvas(game_width, game_height)
        self._canvas_sx = 1
        self._canvas_sy = 1
        self.params = {}
        self._appliedParams = {}

        -- load stored effect
        assert(_effects[name]~=nil, "Effect '"..name.."' not found")
        
        if _effects[name] then
            self.effect_data = _effects[name]

            -- turn options into member variables
            _effects[name].params = ifndef(_effects[name].params, {})

            if not (_effects[name].params["textureSize"] or _effects[name].params["texSize"]) then
                _effects[name].params["texSize"] = {game_width, game_height}
            end

            for p, default in pairs(_effects[name].params) do
                self[p] = default
                self.params[p] = default
                if p == "textureSize" or p == "texSize" then
                    self[p] = {game_width, game_height}
                end
            end 

            -- setup shader
            self._shader = love.graphics.newShader(_effects[name].string)
        end 

        if self.create then self:create() end
        self.ready = true

        _addGameObject('effect',self)
    end,

    update = function(self, dt)
        -- compensates for when window is resized
        Effect._mouse_offx = -((game_width/2) - (self.canvas.width/2))
        Effect._mouse_offy = -((game_height/2) - (self.canvas.height/2))

        if self.time then self.time = self.time + dt end
        if self.dt then self.dt = self.dt + dt end
        if self.screen_size then self.screen_size = {game_width, game_height} end
        if self.inv_screen_size then self.inv_screen_size = {1/game_width, 1/game_height} end
        return self
    end,

    resizeCanvas = function(self, w, h)
        self.canvas:resize(game_width, game_height)
    end,

    applyCanvas = function(self, func, canvas)
        --local curr_canvas = love.graphics.getCanvas()
        local offx = -((game_width/2) - (canvas.width/2))
        local offy = -((game_height/2) - (canvas.height/2))
        canvas:drawTo(function()
        --Draw.stack(function()
            Draw.translate(offx, offy)
            func()
            Draw.translate(-offx, -offy)
        end)
        --end)
        --love.graphics.setCanvas()
    end,

    applyShader = function(self, func, shader, canvas)
        shader = ifndef(shader, self._shader)
        canvas = ifndef(canvas, self.canvas)

        local curr_shader = love.graphics.getShader()
        local curr_color = {love.graphics.getColor()}
        local curr_blend = love.graphics.getBlendMode()

        self.canvas:drawTo(function()
            love.graphics.setBlendMode('alpha', 'premultiplied')
            love.graphics.setShader(shader)
            func()
            love.graphics.setShader()
            love.graphics.setBlendMode(curr_blend)
        end)
        self.canvas:draw()

        love.graphics.setBlendMode(curr_blend)
--[[
        love.graphics.setColor(curr_color)
        love.graphics.setShader(shader)
        love.graphics.setBlendMode('alpha', 'premultiplied')
]]
    end,

    applyParams = function(self)
        -- send variables
        for p, default in pairs(self.effect_data.params) do
            local var_name = p
            local var_value = default

            if self[p] ~= nil and self._appliedParams[var_name] == true then
                var_value = self[p]
                self:send(var_name, var_value)
            end
            self.params[var_name] = var_value
        end
        self._appliedParams = {}
    end,

    draw = function (self, func)
        if self.pause then
            Effect._mouse_offx = 0
            Effect._mouse_offy = 0
            func()
        elseif not self.effect_data.extra_draw then
            self:applyParams()

            if func then
                self:applyShader(func, self._shader, self.canvas)
            end


        -- call extra draw function
        else
            self:applyParams()
            self.effect_data.extra_draw(self, func)
        end
        return self
    end,

    getParam = function(self, name)
        if self[name] then
            return self[name]
        else
            return self.params[name]
        end
    end,

    send = function (self, name, value)
        if type(value) == 'boolean' then
            if value then value = 1 
            else value = 0 end
        end
        self.params[name] = value
        self._appliedParams[name] = true
        self._shader:send(name, value)
        return self
    end
    --[[
    -- bug: self is not passed
    __newindex = function (self, key, value)
        print_r(self)
        print(key, value)
        if self.effect_data.params[key] ~= nil then
            print(key, value)
            self.effect_data.params[key] = value
        else return self[key] end
    end
    ]]
}

local _love_replacements = {
    ["float"] = "number",
    ["sampler2D"] = "Image",
    ["uniform"] = "extern",
    ["texture2D"] = "Texel",
    ["gl_FragColor"] = "pixel",
    ["gl_FragCoord"] = "screen_coords"
}
EffectManager = Class{
    new = function (options)
        local new_eff = {}
        new_eff.string = ifndef(options.shader,'')
        new_eff.params = ifndef(table.deepcopy(options.params), {})
        new_eff.extra_draw = options.draw
        new_eff.warp_effect = ifndef(options.warp_effect, false)

        local var_filler = '' -- avoids error if var is not used in code
        local pre_warp = ''
        local post_warp = ''
        if new_eff.warp_effect then
            pre_warp = 
[[
        vec2 coord =  texCoord * texSize;
]]
            post_warp = 
[[
        gl_FragColor = texture2D(texture, coord / texSize);
        vec2 clampedCoord = clamp(coord, vec2(0.0), texSize);
        if (coord != clampedCoord) {
            gl_FragColor.a *= max(0.0, 1.0 - length(coord - clampedCoord));
        }
]]
        end

        -- automatically include texSize as param
        if not (new_eff.params["textureSize"] or new_eff.params["texSize"]) then
            new_eff.params['texSize'] = {game_width, game_height}
        end

        -- add helper funcs
        if new_eff.string == '' then
            for var_name, value in pairs(new_eff.params) do
                var_filler = var_filler .. var_name .. ';'
                if type(value) == 'table' then
                    new_eff.string = new_eff.string .. "uniform vec"..tostring(#value).." "..var_name..";\n"
                end
                if type(value) == 'number' then
                    new_eff.string = new_eff.string .. "uniform float "..var_name..";\n"
                end
            end
            new_eff.string = new_eff.string.. 
[[
/* From glfx.js : https://github.com/evanw/glfx.js */
float random(vec3 scale, vec2 gl_FragCoord, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(vec3(gl_FragCoord.xy, 0.0) + seed, scale)) * 43758.5453 + seed);
}

float random(vec2 scale, vec2 gl_FragCoord, float seed) {
    return random(vec3(scale.xy, 0), gl_FragCoord, seed);
}

#ifdef VERTEX
    vec4 position(mat4 transform_projection, vec4 vertex_position) {
]]
..ifndef(options.vertex, '')..
[[
        return transform_projection * vertex_position;
    }
#endif

#ifdef PIXEL
    vec4 effect(vec4 in_color, Image texture, vec2 texCoord, vec2 screen_coords){
        vec4 pixel = Texel(texture, texCoord);
]]
..var_filler..'\n'
..pre_warp
..ifndef(options.effect, '')
..post_warp
..[[
        return pixel * in_color;
    }
#endif
]]
            -- port non-LoVE keywords
            local r
            for old, new in pairs(_love_replacements) do
                new_eff.string, r = new_eff.string:gsub(old, new)
            end
        end
        if options.name == 'igloo_shader' then print(new_eff.string) end
        _effects[options.name] = new_eff
        --return Effect(options.name)
    end,

    -- doesn't seem to work
    load = function(file_path)
        love.filesystem.load(file_path)()
    end,

    _render_to_canvas = function(canvas, func)
        local old_canvas = love.graphics.getCanvas()

        love.graphics.setCanvas(canvas)
        love.graphics.clear()
        func()

        love.graphics.setCanvas(old_canvas)
    end
}

-- global shader vals: https://www.love2d.org/wiki/Shader_Variables
-- TODO: update template (see zoom_blur)
EffectManager.new{
    name = 'template',
    params = {['myNum']=1},
    shader = [[
extern number myNum;

#ifdef VERTEX
    vec4 position( mat4 transform_projection, vec4 vertex_position ) {
        return transform_projection * vertex_position;
    }
#endif

#ifdef PIXEL
    // color            - color set by love.graphics.setColor
    // texture          - image being drawn
    // texture_coords   - coordinates of pixel relative to image (x, y)
    // screen_coords    - coordinates of pixel relative to screen (x, y)

    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
        // Texel returns a pixel color after taking in a texture and coordinates of pixel relative to texture
        // Texel -> (r, g, b)
        vec4 pixel = Texel(texture, texture_coords );   

        pixel.r = pixel.r * myNum;
        pixel.g = pixel.g * myNum;
        pixel.b = pixel.b * myNum;
        return pixel;
    }
#endif
    ]]
}

--[[
scale with screen position

vec2 screenSize = love_ScreenSize.xy;        
number factor_x = screen_coords.x/screenSize.x;
number factor_y = screen_coords.y/screenSize.y;
number factor = (factor_x + factor_y)/2.0;

]]--

EffectManager.new{
    name = 'bloom',
    params = {['screen_size']={0,0}, ['samples']=5, ['quality']=1},
    shader = [[
// adapted from http://www.youtube.com/watch?v=qNM0k522R7o

extern vec2 screen_size;
extern int samples; // pixels per axis; higher = bigger glow, worse performance
extern float quality; // lower = smaller glow, better quality

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
  vec4 source = Texel(tex, tc);
  vec4 sum = vec4(0);
  int diff = (samples - 1) / 2;
  vec2 sizeFactor = vec2(1) / screen_size * quality;
  
  for (int x = -diff; x <= diff; x++)
  {
    for (int y = -diff; y <= diff; y++)
    {
      vec2 offset = vec2(x, y) * sizeFactor;
      sum += Texel(tex, tc + offset);
    }
  }
  
  return ((sum / (samples * samples)) + source) * color;
}
    ]]
}

EffectManager.new{
    name = 'crt',
    params = {['angle']=0,['radius']=50,['direction']={0,0}},--['strength'] = {1, 1}, ['size'] = {20, 20}},
    effect = [[
            pixel.r = Texel(texture, texCoord - direction).r; 
            pixel.b = Texel(texture, texCoord + direction).b; 
            pixel.a = Texel(texture, texCoord).a;
            
            if (Texel(texture, texCoord - direction).a > 0 || Texel(texture, texCoord + direction).a > 0)
                pixel.a = 1.0; 
    ]],
    draw = function(self, draw)
        local angle, radius = self.angle, self.radius
        local dx = math.cos(math.rad(angle)) * radius / game_width
        local dy = math.sin(math.rad(angle)) * radius / game_height
        
        self:send("direction", {dx,dy})
        
        self:applyShader(draw)
    end,
}

--[[pixel = vec4(
        Texel(texture, texCoord - direction).r,
        Texel(texture, texCoord).g,
        Texel(texture, texCoord + direction).b,
        1.0);]]

EffectManager.new{
    name = 'zoom blur',
    params = {
    ['center']={0,0}, ['strength']=0.3 
    },
    effect =
[[
        vec4 color = vec4(0.0);
        float total = 0.0;
        vec2 toCenter = center - texCoord * texSize;
        
        /* randomize the lookup values to hide the fixed number of samples */
        float offset = random(vec2(12.9898, 78.233), screen_coords, 0.0);
        
        for (float t = 0.0; t <= 40.0; t++) {
            float percent = (t + offset) / 40.0;
            float weight = 4.0 * (percent - percent * percent);
            vec4 sample = texture2D(texture, texCoord + toCenter * percent * strength / texSize);
            
            /* switch to pre-multiplied alpha to correctly blur transparent images */
            sample.rgb *= sample.a;
            
            color += sample * weight;
            total += weight;
        }
        
        gl_FragColor = color / total;
        
        /* switch back from pre-multiplied alpha */
        gl_FragColor.rgb /= gl_FragColor.a + 0.00001;
]]
    }

EffectManager.new{
    name = 'warp sphere',
    params = {
    ['radius']=50, ['strength']=2, ['center']={0, 0}
    },
    warp_effect=true,
    effect =
[[
        coord -= center;
        float distance = length(coord);
        if (distance < radius) {
            float percent = distance / radius;
            if (strength > 0.0) {
                coord *= mix(1.0, smoothstep(0.0, radius / distance, percent), strength * 0.75);
            } else {
                coord *= mix(1.0, pow(percent, 1.0 + strength * 0.75) * radius / distance, 1.0 - percent);
            }
        }
        coord += center;
]]
}

-- BROKEN
EffectManager.new{
    name = 'grayscale',
    params = {['factor']=1},
    effect =
[[
number average = (pixel.r + pixel.b + pixel.g)/3.0;

pixel.r = pixel.r + (average-pixel.r) * factor;
pixel.g = pixel.g + (average-pixel.g) * factor;
pixel.b = pixel.b + (average-pixel.b) * factor;
]]
}

EffectManager.new{
    name = 'tilt shift',
    params = {['location']={0,0,0,0}, ['strength']=15, ['distance']=200, ['start']={0,0}, ['end']={0,0}, ['delta']={0,0}},
    effect =
[[
    vec4 color = vec4(0.0);
    float total = 0.0;
    
    /* randomize the lookup values to hide the fixed number of samples */
    float offset = random(vec3(12.9898, 78.233, 151.7182), gl_FragCoord, 0.0);
    
    vec2 normal = normalize(vec2(start.y - end.y, end.x - start.x));
    float radius = smoothstep(0.0, 1.0, abs(dot(texCoord * texSize - start, normal)) / distance) * strength;
    for (float t = -30.0; t <= 30.0; t++) {
        float percent = (t + offset - 0.5) / 30.0;
        float weight = 1.0 - abs(percent);
        vec4 sample = texture2D(texture, texCoord + delta / texSize * percent * radius);
        
        /* switch to pre-multiplied alpha to correctly blur transparent images */
        sample.rgb *= sample.a;
        
        color += sample * weight;
        total += weight;
    }
    
    gl_FragColor = color / total;
    
    /* switch back from pre-multiplied alpha */
    gl_FragColor.rgb /= gl_FragColor.a + 0.00001;
]],
    draw = function(self, draw)
        local location = self:getParam('location')

        local dx = location[3] - location[1]
        local dy = location[4] - location[2]
        local d = math.sqrt(dx * dx + dy * dy);

        self:send('start', {location[1], location[2]})
        self:send('end', {location[3], location[4]})
        self:send('delta', {dx / d, dy / d})

        self:applyShader(draw)

        self:send('start', {location[1], location[2]})
        self:send('end', {location[3], location[4]})
        self:send('delta', {-dx / d, dy / d})

        self:applyShader(draw)
    end
}


return Effect