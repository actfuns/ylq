module(..., package.seeall)
function main()
	local d1 = require("huodong.marry.rule")
	local d2 = require("huodong.marry.default_text")

	local s = table.dump(d1, "Rule") .. "\n" .. table.dump(d2, "DefaultText")
	SaveToFile("marry", s)
end
