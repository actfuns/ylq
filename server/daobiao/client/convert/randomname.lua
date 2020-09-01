module(..., package.seeall)
function main()
	local dOri = require("role.randomname")
	local First = {}
	local Male = {}
	local Female = {}
	local x = 1
	for k, v in pairs(dOri) do
		if v.firstName ~= "" then
			table.insert(First, {first=v.firstName, mid=v.midName})
		end
		if v.maleName ~= "" then
			table.insert(Male, v.maleName)
		end
		if v.femaleName ~= "" then
			table.insert(Female, v.femaleName)
		end
	end
	local s = table.dump(First, "FIRST").."\n"..table.dump(Male, "MALE").."\n"..table.dump(Female, "FEMALE")
	SaveToFile("randomname", s)
end
