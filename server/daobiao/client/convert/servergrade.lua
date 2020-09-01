module(..., package.seeall)
function main()
	local d1 = require("role.explimit")
	local d2 = require("role.servergrade")
	local s = table.dump(d1, "ExpLimit") .. "\n" .. table.dump(d2, "DATA")
	SaveToFile("servergrade", s)
end