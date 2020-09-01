module(..., package.seeall)
function main()
	local d1 = require("monster.pata")
	
	local s = table.dump(d1, "PATA")
	SaveToFile("monster", s)
end
