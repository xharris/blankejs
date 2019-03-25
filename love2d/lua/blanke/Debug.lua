Debug = {
    lines = {},
    _font = nil,
    margin = 15,
    _duplicate_count = 0,
    _last_line = '',

    -- records the current seed and all inputs, saves for later
    _recording = false,
    _playing_record = false,
    _record = {},
    recordGame = function()
        Debug._recording = true
        local low, high = randSeed()
        Debug._record.seed = {low,high}
        Debug._record.inputs = {}

        local function addInput(...)
            table.insert(Debug._record.inputs, table.merge({game_time},{...}))
        end

        Signal.on('keypress',function(key)
            addInput('kpress',key)
        end)
        Signal.on('keyrelease',function(key)
            addInput('krelease',key)
        end)
        Signal.on('mousepress',function(x,y,button)
            addInput('mpress',x,y,button)
        end)
        Signal.on('mouserelease',function(x,y,button)
            addInput('mrelease',x,y,button)
        end)
    end,
    playRecording = function(filename)
        filename = filename or 'last_game.rec'
        local file_info = getFileInfo(filename)
        Debug.log("re-running last game")
        if file_info and file_info.type == "file" then
            Debug._playing_record = true
            Debug._record = json.decode(love.filesystem.read(filename))

            randSeed(Debug._record.seed[1], Debug._record.seed[2])
            Debug._play_index = 1
            Debug._event_count = table.len(Debug._record.inputs)
            if Debug._play_index <= Debug._event_count then 
                Debug._next_evt_time = Debug._record.inputs[1][1]
            end
        end
    end,

    quit = function()
        -- write recorded game info
        if Debug._recording then
            local filename = 'last_game.rec'
            local rec_data = json.encode(Debug._record)
            love.filesystem.write(filename, rec_data)
        end
    end,

    _play_index = 1,
    _next_evt_time = 5000,  -- just a random number
    _event_count = 10,      -- another random number
    update = function(dt)
        if Debug._playing_record then
            if game_time >= Debug._next_evt_time and Debug._play_index <= Debug._event_count then
                -- simulate this input
                local input_info = Debug._record.inputs[Debug._play_index]
                if input_info[2] == "kpress" then
                    Input.simulateKeyPress(input_info[3])
                end
                if input_info[2] == "krelease" then
                    Input.simulateKeyRelease(input_info[3])
                end
                if input_info[2] == "mpress" then
                    Input.simulateMousePress(input_info[3],input_info[4],input_info[5])
                end
                if input_info[2] == "mrelease" then
                    Input.simulateMouseRelease(input_info[3],input_info[4],input_info[5])
                end
                -- wait for next input event
                Debug._play_index = Debug._play_index + 1
                if Debug._play_index <= Debug._event_count then
                   Debug._next_evt_time = Debug._record.inputs[Debug._play_index][1]
                end
            end
        end
    end,

    draw = function()
        local fnt_height = Draw.font:getHeight()
        local win_height = love.graphics:getHeight()
        local lines = math.min(game_height / fnt_height, #Debug.lines)

        Draw.push()
        Draw.setFont(Debug._font)
        Draw.setColor(1,0,0,1)
        for i_line = 1, lines do
            line = Debug.lines[i_line]

            local alpha = 255
            local y = (i_line-1)*fnt_height
            if y > win_height/2 then
                alpha = 255 - ((y-win_height/2)/(win_height/2)*255)
            end 

            Draw.setAlpha(alpha)
            Draw.text(line, BlankE.left + Debug.margin, y+Debug.margin)
        end
        Draw.pop()
        love.graphics.setColor(255,255,255,255)
        return Debug
    end,

    setFontSize = function(new_size)
        Debug._font = Font{name="console",size=new_size}
        return Debug
    end,

    setMargin = function(new_margin)
        Debug.margin = new_margin
        return Debug
    end,
    
    log = function(...)
        local line_height = 16 
        if Draw.font then line_height = Draw.font:getHeight() end

        local new_line = table.concat(table.toString({...}),'\t')        
        if Debug._last_line == new_line then
            Debug._duplicate_count = Debug._duplicate_count + 1
            Debug.lines[1] = new_line .. '('..(Debug._duplicate_count+1)..')'
        else
            Debug._duplicate_count = 0
            
            table.insert(Debug.lines, 1, new_line)
            if #Debug.lines > (game_height / line_height) then
                Debug.lines[#Debug.lines] = nil
            end
        end
        Debug._last_line = new_line
        print(new_line)
        return Debug
    end,

    clear = function()
        if BlankE._ide_mode then CONSOLE.clear() end
        Debug.lines = {}
        return Debug
    end
}
io.output():setvbuf("no")
return Debug