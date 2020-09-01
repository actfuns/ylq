module(..., package.seeall)
function main()
	local d = require("role.roletype")
	local dMap = {}
	for k, v in pairs(d) do
		if not dMap[v.sex] then
			dMap[v.sex] = {}
		end
		dMap[v.sex][v.school] = k
	end
	
	local d2 = require("role.branchtype")
	
	local t = {}
	local d3 = require("role.onfight")
	table.insert(t, table.dump(d3, "FightAmount"))
	
	local s = table.dump(d, "DATA").."\n--sex-school\n"..table.dump(dMap, "MAP").."\n"..table.dump(d2, "BRANCH_TYPE")
	local listStr = table.concat(t, "\n")
	SaveToFile("roletype", s..listStr)
end
