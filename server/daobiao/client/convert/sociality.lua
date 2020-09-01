module(..., package.seeall)
function main()
	local d = require("huodong.sociality.sociality")

	local d_out = {}
	local function d_outSortFunc(v1, v2)
		return d[v1].sort_id < d[v2].sort_id
	end
	for k,v in pairs(d) do
		table.insert(d_out, v.id)
	end
	table.sort(d_out, d_SortFunc)

	local s = table.dump(d, "DATA").."\n"..table.dump(d_out, "Sort")
	SaveToFile("sociality", s)
end
