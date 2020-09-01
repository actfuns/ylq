module(..., package.seeall)
function main()
	local d1 = require("huodong.dailysign.week")
	local d2 = require("huodong.dailysign.signtype")

	local s = table.dump(d1, "SecondTest") .. "\n" .. table.dump(d2, "TotalRecharge")
	 .. "\n" .. table.dump(d3, "WelfareControl")
	SaveToFile("welfare", s)
end
