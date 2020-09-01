module(..., package.seeall)
function main()
	local d = require("foretell.foretell")
	local s = table.dump(d, "DATA")
	SaveToFile("foretell", s)
end
