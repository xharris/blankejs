--[[
completely working effects:
 - chroma shift : angle(rad), radius
 - crt : lineSize(vec2) opacity, scanlines(bool), distortion, inputGamma, outputGamma
 - outline : size
 - static : amount(vec2)
 - bloom : samples (int), quality (float)
]]

Effect = Class{
    new = function(...) return EffectManager.new(...) end,

    init = function(self, ...)
        self.shaders = {}
        self.spare_canvas = Canvas()
        self.canvas = Canvas()

        local names = {...}
        for n, name in ipairs(names) do
            self:add(name)
        end

        _addGameObject('effect',self)
    end,

    add = function(self, name) 
        table.insert(self.shaders, Shader(name))
        self[name] = {}
    end,

    update = function(self, dt)
        for s, shader in ipairs(self.shaders) do
            shader:update(dt)         
        end
    end,

    resizeCanvas = function(self, w, h)
        self.canvas:resize(game_width, game_height)
    end,

    draw = function(self, fn)
        self.spare_canvas:drawTo(fn)

        for s, shader in ipairs(self.shaders) do
            -- apply any params set
            if self[shader.name] then
                for param, val in pairs(self[shader.name]) do
                    shader:send(param, val)
                end
            end

            self.canvas:drawTo(function()
                shader:apply(fn, self.spare_canvas)
            end)
            self.spare_canvas:drawTo(function() self.canvas:draw() end)
        end

        self.canvas:draw()
    end
}

Shader = Class{
    _mouse_offx = 0,
    _mouse_offy = 0,

    init = function(self, name)
        self._shader = nil
        self.name = name

        self.params = {}        -- current values of all params
        self.appliedParams = {} -- keeps track of whether send() was used on a param

        assert(EffectManager.effects[name]~=nil, "Effect '"..name.."' not found")

        self:reset()
    end,

    reset = function(self)
        local params = EffectManager.effects[self.name].params

        -- set the default parameter values
        for key, val in pairs(params) do
            self[key] = val
            self.params[key] = val
            self.appliedParams[key] = false
        end

        -- reset time and other values
        self.time = 0
        self.dt = 0
        self.screen_size = {game_width, game_height}
        self.inv_screen_size = {1/game_width, 1/game_height}
        --self._mouse_offx = -((game_width/2) - (self.canvas.width/2))
        --self._mouse_offy = -((game_height/2) - (self.canvas.height/2))

        self._shader = love.graphics.newShader(EffectManager.effects[self.name].string)
    end,

    resizeCanvas = function(self, w, h)
        --self.canvas:resize(game_width, game_height)
    end,

    apply = function(self, func, canvas)
        self:applyParams()

        local curr_shader = love.graphics.getShader()
        local curr_blend = love.graphics.getBlendMode()

	    love.graphics.setBlendMode('alpha', 'premultiplied') 
	    love.graphics.setShader(self._shader)
        canvas:draw()
        love.graphics.setBlendMode(curr_blend)
        love.graphics.setShader(curr_shader)
    end,

    applyParams = function(self)
        local params = EffectManager.effects[self.name].params
        for key, val in pairs(params) do
            if not self.appliedParams[key] then

                local val
                if self[key] then val = self[key] 
                elseif self.params[key] then val = self.params[key] 
                else val = params[key] end

                self:send(key, val)

            end
            self.appliedParams[key] = false
        end
        self:send("time", self.time)
    end, 

    send = function(self, key, value) 
        if self.params[key] ~= nil then
            if type(value) == 'boolean' then
                if value ~= 0 then value = 1 end
            end

            self.params[key] = value
            self.appliedParams[key] = true
            self._shader:send(key, value)
        end

        return self
    end,

    update = function(self, dt)
        --self._mouse_offx = -((game_width/2) - (self.canvas.width/2))
        --self._mouse_offy = -((game_height/2) - (self.canvas.height/2))

        self.time = self.time + dt
        self.dt = self.dt + dt
        self.screen_size = {game_width, game_height}
        self.inv_screen_size = {1/game_width, 1/game_height}
    end,

    draw = function(self, fn)
        if self.pause then
            fn()

        else

            local extra_draw = EffectManager.effects[self.name].extra_draw
            if extra_draw then
                extra_draw(self, fn)
            else
                self:apply(fn)
            end

        end
        return self
    end,
}

EffectManager = Class{
    effects = {},
    love_replacements = {
        ["float"] = "number",
        ["sampler2D"] = "Image",
        ["uniform"] = "extern",
        ["texture2D"] = "Texel",
        ["gl_FragColor"] = "pixel",
        ["gl_FragCoord"] = "screen_coords"
    },

    new = function(options)
        local new_eff = {}

        options.shader = ifndef(options.shader,'')
        options.effect = ifndef(options.effect,'')
        options.vertex = ifndef(options.vertex,'')

        new_eff.string = options.shader
        new_eff.params = ifndef(table.deepcopy(options.params), {})
        new_eff.extra_draw = options.draw
        new_eff.warp_effect = ifndef(options.warp_effect, false)
        new_eff.use_canvas = ifndef(options.use_canvas, true)
        new_eff.integers = ifndef(options.integers, {})

        if new_eff.string ~= '' then
            new_eff.params = {}
        end

        -- texSjze is mandatory
        if not (new_eff.params["textureSize"] or new_eff.params["texSize"]) then
            new_eff.params["texSize"] = {game_width, game_height}
        end
        if not (new_eff.params["time"]) then
            new_eff.params["time"] = 0
        end

        local param_string = '' -- avoids error that appears if a variable is not used

        -- if using a warp effect
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

        param_init = ''
    	param_string = ''
    	param_init = ''
        -- turn param list into code
        for key, val in pairs(new_eff.params) do
            -- dont add parameter initialization if it's not used in the code
            if options.shader:contains(key) or options.effect:contains(key) or options.vertex:contains(key) then
                param_string = param_string .. key .. ';'
                
                if type(val) == 'table' then
                    param_init = param_init .. "uniform vec"..tostring(#val).." "..key..";\n"
                end
                if type(val) == 'number' then
                    if table.find(new_eff.integers, key) then
                        param_init = param_init .. "uniform int "..key..";\n"
                    else
                        param_init = param_init .. "uniform float "..key..";\n"
                    end
                end
            else
                -- prevents Effect:send from auto-sending unused parameters
                new_eff.params[key] = nil
            end
        end

        new_eff.string = param_init..new_eff.string

        if options.shader == '' then
            new_eff.string = new_eff.string.. 
[[/* From glfx.js : https://github.com/evanw/glfx.js */
float random(vec2 scale, vec2 pixelcoord, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(pixelcoord + seed, scale)) * 43758.5453 + seed);
}

float getX(float amt) { return amt / love_ScreenSize.x; }

float getY(float amt) { return amt / love_ScreenSize.y; }

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
..param_string..'\n'
..pre_warp
..ifndef(options.effect, '')
..post_warp
..[[
        return pixel * in_color;
    }
#endif
]]

        end
        -- replace all non-LoVE keywords
        local r
        for old, new in pairs(EffectManager.love_replacements) do
            new_eff.string, r = new_eff.string:gsub(old, new)
        end

        EffectManager.effects[options.name] = new_eff
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

EffectManager.new{
    name = 'bloom',
    params = {['samples']=5, ['quality']=1},
    integers = {'samples'},
    effect = [[
  vec4 source = Texel(texture, texCoord);
  vec4 sum = vec4(0);
  int diff = (samples - 1) / 2;
  vec2 sizeFactor = vec2(1) / love_ScreenSize.xy * quality;
  
  for (int x = -diff; x <= diff; x++)
  {
    for (int y = -diff; y <= diff; y++)
    {
      vec2 offset = vec2(x, y) * sizeFactor;
      sum += Texel(texture, texCoord + offset);
    }
  }
  
  pixel = ((sum / (samples * samples)) + source);

    ]]
}

EffectManager.new{
    name = 'chroma shift',
    params = {['angle']=0,['radius']=50,['direction']={0,0}},--['strength'] = {1, 1}, ['size'] = {20, 20}},
    effect = [[
            if ((pixel.r != pixel.b && pixel.b != pixel.g) && pixel.r != 1.0) {
                pixel.r = Texel(texture, texCoord - direction).r; 
                pixel.b = Texel(texture, texCoord + direction).b; 
                pixel.a = Texel(texture, texCoord).a; 
            }
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
    float offset = random(vec3(12.9898, 78.233, 151.7182), screen_coords, 0.0);
    
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

Effect.new{
    name="outline",
    params={size=1},
    effect=[[
        float incr = 1.0 / love_ScreenSize.x;
        float max = size / love_ScreenSize.x;
        
        vec4 pixel_l, pixel_r, pixel_u, pixel_d, pixel_lu, pixel_ru, pixel_ld, pixel_rd;
        for (float s = 0; s < max; s += incr) {
            pixel_l = Texel(texture, vec2(texCoord.x-s, texCoord.y));
            pixel_r = Texel(texture, vec2(texCoord.x+s, texCoord.y));
            pixel_u = Texel(texture, vec2(texCoord.x, texCoord.y-s));
            pixel_d = Texel(texture, vec2(texCoord.x, texCoord.y+s));
    
            pixel_lu = Texel(texture, vec2(texCoord.x-s, texCoord.y-s));
            pixel_ru = Texel(texture, vec2(texCoord.x-s, texCoord.y+s));
            pixel_ld = Texel(texture, vec2(texCoord.x+s, texCoord.y-s));
            pixel_rd = Texel(texture, vec2(texCoord.x+s, texCoord.y+s));

            if (pixel.a == 0 && (pixel_l.a > 0 || pixel_r.a > 0 || pixel_u.a > 0 || pixel_d.a > 0 || pixel_lu.a > 0 || pixel_ru.a > 0 || pixel_ld.a > 0 || pixel_rd.a > 0)) 
                pixel = vec4(1,0,0,1);
        }
    ]]
}

EffectManager.new{
	name="static",
	params={amount={5,5}},
	effect=[[
		pixel = Texel(texture, vec2(
			texCoord.x + getX(random(vec2(0, 2.0), screen_coords, time) - 1.0) * amount.x,
			texCoord.y + getY(random(vec2(0, 2.0), screen_coords, time) - 1.0) * amount.y
		));
	]]
}

return Effect