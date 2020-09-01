module(..., package.seeall)
function main()
	local d1 = require("huodong.trapmine.scenemonster")
	local s = table.dump(d1, "SCENEDATA")
	SaveToFile("autorun", s)
end