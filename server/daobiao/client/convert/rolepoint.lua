module(..., package.seeall)
function main()
	local d1 = require("role.point")
	local d2 = require("role.washpoint")
	local d3 = require("role.roleprop")
	local dNew = {}
	for k, v in pairs(d1) do
		local key = v.macro
		local value = {
			hp = v.hp_max_add,
			mp = 0,
			speed = v.speed_add,
			phy_attack = v.phy_attack_add,
			mag_attack = v.mag_attack_add,
			phy_defense = v.phy_defense_add,
			mag_defense = v.mag_defense_add,

		}
		dNew[key] = value
	end
	local s = table.dump(dNew, "ROLEPOINT").."\n"..table.dump(d2, "LEVEL").."\n"..table.dump(d3, "INIT")
	SaveToFile("rolepoint", s)
end