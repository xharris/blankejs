local words = "sh1t.sh! t"

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
local decrypted = decrypt(encrypted, 50)
local word_table = decrypted:split('.')
local replacements = {
	['4']=a,
	['8']=b,['13']=b,
	['1']=l,
	['!']=i,
	['0']=o,
	['5']=s
	['7']=t
}
local accents = 	"ç,æ,œ,á,é,í,ó,ú,à,è,ì,ò,ù,ä,ë,ï,ö,ü,ÿ,â,ê,î,ô,û,å,ø,Ø,Å,Á,À,Â,Ä,È,É,Ê,Ë,Í,Î,Ï,Ì,Ò,Ó,Ô,Ö,Ú,Ù,Û,Ü,Ÿ,Ç,Æ,Œ"
local accent_conv =	"c,ae,oe,a,e,i,o,u,a,e,i,o,u,a,e,i,o,u,y,a,e,i,o,u,a,o,O,A,A,A,A,A,E,E,E,E,I,I,I,I,O,O,O,O,U,U,U,U,Y,C,AE,OE"
local t_accent_conv = accent_conv:split(',')
for a, acc in ipairs(accents:split(',')) do 
	replacements[acc] = t_accent_conv[a]
end

isBadWord = function(str)
	-- print_r(word_table)
end
