module(..., package.seeall)
function main()
	local d1 = require("huodong.pata.pata")

	local s1 = table.dump(d1, "DATA")
	SaveToFile("pata", s1)
end
