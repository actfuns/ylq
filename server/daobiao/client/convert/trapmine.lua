module(..., package.seeall)
function main()
	local d1 = require("huodong.trapmine.trapmine")
	local d2 = require("huodong.trapmine.npc")
	
	local d3 = require("huodong.trapmine.monster_pool")
	local d4 = require("huodong.trapmine.map_tips")
	local t3 = {}
	local map = {}
	for k,v in pairs(d3) do
		if map[v.map_id] == nil then
			map[v.map_id] = v.map_id
			table.insert(t3, v.map_id)
		end
	end
	
	local s = table.dump(d1, "DATA").."\n"..table.dump(d2, "NPC").."\n"..table.dump(t3, "MAP_GROUP").."\n"..table.dump(d4, "MAP_TIPS")

	SaveToFile("anlei", s)
end
