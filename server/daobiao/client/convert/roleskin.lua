module(..., package.seeall)
function main()
	local d = require("role.roleskin")
	local s = table.dump(d, "DATA")
	SaveToFile("roleskin", s)
end
