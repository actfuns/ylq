module(..., package.seeall)
function main()
	local d1 = require("huodong.equipfuben.floor")
	local d2 = require("huodong.equipfuben.fuben")
	local d3 = require("huodong.equipfuben.config")
	local d4 = require("huodong.equipfuben.reset_cost")
	local t4 = {}
	for k, v in pairs(d4) do
		table.insert(t4, v)
	end
	if #t4 > 1 then
		table.sort(t4, function(a, b) return a.num < b.num end )
	end
	
	local d5 = require("playconfig.equipfuben")
	local s1 = table.dump(d1, "FLOOR")
	local s2 = table.dump(d2, "FUBEN")
	local s3 = table.dump(d3, "CONFIG")
	local s4 = table.dump(t4, "RESET_COST")
	local s5 = table.dump(d5, "PLAYER_CONFIG")
	local d6 = require("huodong.equipfuben.map_tips")
	local s6 = table.dump(d6, "MAP_TIPS")
	
	SaveToFile("equipfuben", s1.."\n"..s2.."\n"..s3.."\n"..s4.."\n"..s5.."\n"..s6)
end
