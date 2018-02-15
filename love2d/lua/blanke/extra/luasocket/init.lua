http = require("socket.http")
local ltn12 = require("ltn12")

function url_encode(str)
  if (str) then
    str = string.gsub(str, " ", "%%20")
  end
  return str	
end

http.get = function(url)
	local t = {}
  	local status, code, headers = http.request{
    	url=url_encode(url),
    	sink=ltn12.sink.table(t)
    }
  	return {["data"]=assert(table.concat(t)), ["status"]=status, ["headers"]=headers, ["code"]=code}
end