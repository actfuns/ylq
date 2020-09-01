module(..., package.seeall)
function main()
	local d = require("huodong.hunt.config")
	
	local s = table.dump(d, "DATA")
	SaveToFile("hunt", s)
end
