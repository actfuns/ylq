module(..., package.seeall)
function main()
	local d1 = require("system.rank.rankinfo")
	local d2 = require("system.rank.ranktype")
	local d3 = require("system.rank.grade_rank_reward")
	local d4 = require("system.rank.handletype")
	local d5 = require("system.rank.attribute")

	local d6 = require("system.rank.rushrank")
	local d7 = require("system.rank.rushconfig")

	for k,v in pairs(d1) do
		v.handle_id = d4[v.handle_id].define_id
	end

	local d2_Sort = {}
	for k,v in pairs(d2) do
		table.insert(d2_Sort, v.id)
	end

	local function d2_sortFunc(v1, v2)
		return d2[v1].sortid < d2[v2].sortid
	end

	for k,v in pairs(d2) do
		for i=1,#v.subid do
			d1[v.subid[i]].parent_id = v.id
		end
	end

	table.sort(d2_Sort, d2_sortFunc)

	local d6_out = {}
	for k,v in pairs(d6) do
		if d6_out[v.rank_id] == nil then
			d6_out[v.rank_id] = {}
		end
		if d6_out[v.rank_id][v.subtype] == nil then
			d6_out[v.rank_id][v.subtype] = {}
		end
		d6_out[v.rank_id][v.subtype][v.rank] = v
	end

	local d7_out = {}
	for k,v in pairs(d7) do
		table.insert(d7_out, k)
	end
	local function d7_sortFunc(v1, v2)
		return d7[v1].sort_id < d7[v2].sort_id
	end
	table.sort(d7_out, d7_sortFunc)

	local s = table.dump(d1, "DATA") .. "\n" .. table.dump(d2, "RankType") .. "\n" .. table.dump(d2_Sort, "RankTypeSort")
	 .. "\n" .. table.dump(d3, "RankReward") .. "\n" .. table.dump(d5, "Attribute") .. "\n" .. table.dump(d6_out, "RushReward")
	 .. "\n" .. table.dump(d7_out, "RushSort") .. "\n" .. table.dump(d7, "RushConfig")
	
	SaveToFile("rank", s)
end