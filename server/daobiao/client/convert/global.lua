module(..., package.seeall)
function main()
	local d1 = require("global")
	local s = table.dump(d1, "GLOBAL")
	SaveToFile("global", s)
end
