module(..., package.seeall)
function main()
	local d1 = require("huodong.block_control")
	local t1 = {}
	for k, v in pairs(d1) do
		t1[v.name] = v
	end	
	local s1 = table.dump(t1, "DATA") 
	SaveToFile("huodongblock", s1)
end