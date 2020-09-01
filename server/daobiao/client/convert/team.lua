module(..., package.seeall)
function main()
	local d1 = require("team.autoteam")
	local d2 = require("team.refuse_config")
	local s = table.dump(d1, "AUTO_TEAM").."\n"..table.dump(d2, "REFUSE_CONFIG")
	SaveToFile("team", s)
end