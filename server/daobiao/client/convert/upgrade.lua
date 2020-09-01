module(..., package.seeall)
function main()
	local dOri = require("role.upgrade")
	for i, v in ipairs(dOri) do
		v.sum_player_exp = 0
		v.sum_summon_exp = 0
		for j=1, i do
			v.sum_player_exp = v.sum_player_exp + dOri[j].player_exp
			v.sum_summon_exp = v.sum_summon_exp + dOri[j].summon_exp
		end

	end
	local s = table.dump(dOri, "DATA")
	SaveToFile("upgrade", s)
end
