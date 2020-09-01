module(..., package.seeall)
function main()
	local d = require("arena.arena")
	local d2 = require("arena.avatar_uv")
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
	local s = table.dump(d, "DATA") .. "\n" .. table.dump(d1, "SortId") .. "\n" .. table.dump(d2, "Avatar_UV")
	SaveToFile("arena", s)
end
