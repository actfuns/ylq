module(..., package.seeall)
function main()
	local d1 = require("huodong.msattack.path_config")
	local d2 = require("huodong.msattack.defense_reward")
	local d3 = require("huodong.msattack.rank_reward")
	local d4 = require("huodong.msattack.defense_region")
	local dSumwave = require("huodong.msattack.refresh")
	local s1 = table.dump(d1, "PathConfig")
	local s2 = table.dump(d2, "DefenseReward")
	local s3 = table.dump(d3, "RankReward")
	local s4 = table.dump(d4, "DefenseRegion")
	local sSumwave = "SUMWAVE=".."\""..dSumwave[#dSumwave].wave.."\""
	SaveToFile("msattack", sSumwave.."\n"..s1.."\n"..s2.."\n"..s3.."\n"..s4)
end
