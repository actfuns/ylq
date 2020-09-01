module(..., package.seeall)
function main()
	local d1 = require("global_control")
	local s = table.dump(d1, "GLOBAL_CONTROL")
	SaveToFile("globalcontrol", s)
end
