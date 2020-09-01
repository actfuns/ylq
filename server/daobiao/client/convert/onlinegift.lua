module(..., package.seeall)

function main()
	local d1 = require("huodong.onlinegift.onlinegift")
	local d1_out = {}

	for k,v in pairs(d1) do
		d1_out[k] = v.id
	end
	local function sortFunc(v1, v2)
		return d1[v1].online_time < d1[v2].online_time
	end
	table.sort(d1_out, sortFunc)

	local s = table.dump(d1, "DATA").."\n"..table.dump(d1_out, "SortID")
	SaveToFile("onlinegift", s)
end
