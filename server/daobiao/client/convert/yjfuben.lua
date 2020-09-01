module(..., package.seeall)
function main()
	local strList = {}
	local d1 = require("huodong.yjfuben.npc")
	table.insert(strList, table.dump(d1, "NPC"))
	
	local d2 = require("huodong.yjfuben.minimap")
	table.insert(strList, table.dump(d2, "MINIMAP"))
	
	local d3 = require("huodong.yjfuben.reward")
	table.insert(strList, table.dump(d3, "REWARD"))
	
	local d4 = require("huodong.yjfuben.bossdesc")
	table.insert(strList, table.dump(d4, "BossDesc"))

	local result = table.concat(strList, "\n")
	SaveToFile("yjfuben", result)
end
