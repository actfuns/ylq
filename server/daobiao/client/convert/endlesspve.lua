module(..., package.seeall)
function main()
	local d2 = require("huodong.endless_pve.mode_info")
	

	local s = table.dump(d2, "ModeInfo")
	SaveToFile("endlesspve", s)
end
