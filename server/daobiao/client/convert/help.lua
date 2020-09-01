module(..., package.seeall)
function main()
	local d = require("help.help")
	local s = table.dump(d, "DATA")
	SaveToFile("help", s)
end
