module(..., package.seeall)
function main()
	local d1 = require("huodong.pefuben.fuben")
	local d2 = require("huodong.pefuben.reset_cost")
	
	local s1 = table.dump(d1, "FUBEN")
	local s2 = table.dump(d2, "COST")
	SaveToFile("pefuben", s1.."\n"..s2)
end
