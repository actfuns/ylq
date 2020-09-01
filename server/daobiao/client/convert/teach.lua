module(..., package.seeall)
function main()

	local d1 = require("task.teach.task")
	local d2 = require("task.teach.progress_reward")
	local d3 = require("task.teach.guide")

	-- for k,v in pairs(d1) do
	-- 	if string.sub(v.desc, string.len(v.desc), -1) == "]" then
	-- 		v.desc = v.desc .. " "
	-- 	end
	-- end
	local d1_Sort = {}
	for k,v in pairs(d1) do
		table.insert(d1_Sort, v.id)
	end

	local function d1_SortFunc(v1, v2)
		return d1[v1].min_lv < d1[v2].min_lv
	end
	table.sort(d1_Sort, d1_SortFunc)

	local s = table.dump(d1, "DATA").."\n"..table.dump(d2, "ProgressReward")..
	"\n"..table.dump(d3, "Guide") .. "\n"..table.dump(d1_Sort, "ShowSort")
	SaveToFile("teach", s)
end
