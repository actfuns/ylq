module(..., package.seeall)
function main()
	local d = require("huodong.equalarena.arena")
	local d2 = require("huodong.equalarena.reward_config")
	local d3 = require("huodong.equalarena.partner")
	local d1 = {}
	for k,v in pairs(d) do
		table.insert(d1,k)
	end
	local function sortfunction(v1, v2)
		return d[v1].basescore > d[v2].basescore
	end
	table.sort(d1, sortfunction)
	for k,v in pairs(d1) do
		d[v].sortId = k
	end
	local s = table.dump(d, "DATA") .. "\n" .. table.dump(d1, "SortId") .. "\n" .. table.dump(d2, "Reward")
	 .. "\n" .. table.dump(d3, "Partner")
	SaveToFile("equalarena", s)
end
