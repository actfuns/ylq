module(..., package.seeall)
function main()
	local d1 = require("huodong.lilian.lilian")
	local s = table.dump(d1, "DATA")
	SaveToFile("lilian", s)
end
