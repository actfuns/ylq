module(..., package.seeall)
function main()
	local d1 = require("tollgate.pata")
	local t_d1 = { }
	for k, v in pairs(d1) do
		local key = v.id % 10000
		if key < 1000 then
			t_d1[key] = v 
		else
			t_d1[v.id] = v
		end
	end
	
	
	local s = table.dump(t_d1, "PATA")
	SaveToFile("tollgate", s)
end
