module(..., package.seeall)
function main()
	local t = {}
	local d1 = require("huodong.fieldboss.npc")
	table.insert(t, table.dump(d1, "NPC"))
	
	local d2 = require("huodong.fieldboss.fieldboss_config")
	table.insert(t, table.dump(d2, "BossConfig"))
	SaveToFile("fieldboss", table.concat(t, "\n"))
end
