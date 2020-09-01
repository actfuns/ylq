module(..., package.seeall)
function main()
	local d1 = require("huodong.clubarena.config")
	local s = table.dump(d1, "Config")
	SaveToFile("clubarena", s)
end
