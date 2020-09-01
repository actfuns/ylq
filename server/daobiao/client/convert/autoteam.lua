module(..., package.seeall)
function main()
	local d1 = require("autoteam")
	local s = table.dump(d1, "DATA")
	SaveToFile("autoteam", s)
end