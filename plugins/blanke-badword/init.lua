local words = "bob cobs a dob"

function encrypt(str,code)
	-- character table
    chars="1234567890!@#$%^&*()qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM ,<.>/?;:'[{]}\\|`~"
	-- new code begin
    newcode=""
	-- we start
    for i=1, 999 do
        if string.sub(str,i,i) == "" then
            break
        else
			com=string.sub(str,i,i)
		end
        for x=1, 90 do
			cur=string.sub(chars,x,x)
			if com == cur then
				new=x+code
				while new > 90 do
					new = new - 90
				end
				newcode=""..newcode..""..string.sub(chars,new,new)..""
			end
		end
    end
    return newcode
end

function decrypt(str,code)
	-- character table
    chars="1234567890!@#$%^&*()qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM ,<.>/?;:'[{]}\\|`~"
	-- new code begin
    newcode=""
	-- we start
    for i=1, 999 do
        if string.sub(str,i,i) == "" then
            break
        else
			com=string.sub(str,i,i)
		end
        for x=1, 90 do
			cur=string.sub(chars,x,x)
			if com == cur then
				new=x-code
				while new < 0 do
					new = new + 90
				end
				newcode=""..newcode..""..string.sub(chars,new,new)..""
			end
		end
    end
    return newcode
end

local encrypted = encrypt(words, 50) -- words:gsub(".", function(bb) return "\\" .. bb:byte() end) or words .. "\""


isBadWord = function(str)
    print('encrypt')
    print(encrypted)
    print('decrypt')
    print(decrypt(encrypted, 50))
end
