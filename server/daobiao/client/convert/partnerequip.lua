module(..., package.seeall)
function main()
	local t = {}
	
	
	-- local d3 = require("item.equip_upgrade")
	-- table.insert(t, table.dump(d3, "UPGRADE"))
	
	local d4 = require("item.equip_attr_info")
	table.insert(t, table.dump(d4, "EQUIPATTR"))
	
	-- local d5 = require("item.partner_equip_star")
	-- table.insert(t, table.dump(d5, "EQUIPCOMPOSE"))
	
	local d6 = require("item.partner_equip_getway")
	table.insert(t, table.dump(d6, "EquipGetWay"))

	local d7 = require("item.parequip_star")
	table.insert(t, table.dump(d7, "ParEquip2Stone"))

	local d8 = require("item.parstone_pos")
	table.insert(t, table.dump(d8, "ParStone2Count"))

	local d = require("item.parsoul_upgrade")
	table.insert(t, table.dump(d, "ParSoulUpGrade"))

	local d = require("item.parsoul_set")
	table.insert(t, table.dump(d, "ParSoulType"))

	local d = require("item.parsoul_pos")
	table.insert(t, table.dump(d, "ParSoulUnlock"))

	local d = require("item.parequip_unlock")
	table.insert(t, table.dump(d, "ParEquipUnlock"))

	local d = require("item.parsoul_attr")
	table.insert(t, table.dump(d, "ParSoulAttr"))

	SaveToFile("partnerequip", table.concat(t, "\n"))
end
