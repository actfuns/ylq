module(..., package.seeall)
function main()
	local dExcel = require("role.model")
	local dConfig = {}
	for i, v in pairs(dExcel) do
		dConfig[v.id] = v
	end
	local s = table.dump(dConfig, "CONFIG")
	SaveAllDataToFile("model", s)
end
