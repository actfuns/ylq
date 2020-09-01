module(..., package.seeall)
function main()
	local czjj = require("huodong.charge.grade_gift")
	local privilege = require("huodong.charge.privilege")
	local s1 = table.dump(czjj, "CZJJ_DATA")
	local s2 = table.dump(privilege, "PRIVILEGE")
	SaveToFile("charge", s1.."\n"..s2)
end
