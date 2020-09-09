-- A function in Lua similar to PHP's print_r, from http://luanet.net/lua/function/print_r

function print_r ( main_t ) 
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    pos = tostring(pos)
                    if (type(val)=="table") then
                        print(indent..pos..": "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    else
                        print(indent..pos..": "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    print("*"..tostring(main_t)..": {")
    sub_print_r(main_t,"\t")
    print("}")
end