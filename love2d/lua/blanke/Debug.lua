Debug = {
    lines = {},
    _font = love.graphics.newFont(12),
    margin = 15,
    _duplicate_count = 0,
    _duplicate_line = '',
    
    draw = function()
        for i_line, line in ipairs(Debug.lines) do
            love.graphics.push()
            local alpha = 255
            local y = BlankE.top + (i_line-1)*Debug._font:getHeight()
            if y > love.graphics:getHeight()/2 then
                alpha = 255 - ((y-love.graphics:getHeight()/2)/(love.graphics:getHeight()/2)*255)
            end
            love.graphics.setColor(255,0,0,alpha)
            love.graphics.setFont(Debug._font)
            love.graphics.print(line, BlankE.left + Debug.margin, y+Debug.margin)
            love.graphics.pop()
        end
        love.graphics.setColor(255,255,255,255)
        return Debug
    end,

    setFontSize = function(new_size)
        Debug._font = love.graphics.newFont(new_size)
        return Debug
    end,

    setMargin = function(new_margin)
        Debug.margin = new_margin
        return Debug
    end,
    
    log = function(...)
        local new_line = table.concat(table.toString({...}),'\t')
        if #Debug.lines > 1 and Debug.lines[1] == new_line or Debug._duplicate_line == new_line then
            Debug._duplicate_count = Debug._duplicate_count + 1
            
            if Debug._duplicate_line == '' then
                Debug._duplicate_line = new_line
            end

            new_line = new_line .. '('..Debug._duplicate_count..')'

            Debug.lines[1] = new_line
        else
            Debug._duplicate_count = 0
            Debug._duplicate_line = ''
            
            table.insert(Debug.lines, 1, new_line)
        end
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