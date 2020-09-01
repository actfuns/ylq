module(..., package.seeall)
function main()
	local dOri = require("perform.buff")
	local dAll= {}
	for k, v in pairs(dOri) do
		local dOne = {
			name = v.name,
			desc = v.desc,
			tips_effect = v.tips_effect,
			sub_type = v.sub_type[1],
			show_effect = v.show_effect,
			icon = v.icon,
			-- event = eventMap[v.event],
		}
		dAll[k] = dOne
	end
	local s = table.dump(dAll, "DATA")
	SaveToFile("buff", s)
end
