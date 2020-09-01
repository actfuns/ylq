module(..., package.seeall)
function main()
	local d1 = require("item.itemother")
	local d2 = require("item.itemvirtual")
	local d3 = require("item.equip")
	local d5 = require("item.equipstone")
	local d6 = require("item.fuwen")
	local d7 = require("item.gem")
	local d9 = require("item.strength")
	
	local t_d6 = {}
	for k, v in ipairs(d6) do 
		t_d6[v.equip_pos] = t_d6[v.equip_pos] or {}
		table.insert(t_d6[v.equip_pos], v)	
	end
	
	local t_d9 = {}
	for k,v in pairs(d9) do	
		t_d9[v.equipPos] = t_d9[v.equipPos] or {}
		table.insert(t_d9[v.equipPos], v) 
	end
	local d10 = require("item.gem_level")
	
	local d12 = require("item.housegift")
	local d13 = require("item.awake_item")
	local d14 = require("item.schoolweapon")
	local d15 = require("item.module_src")
	local d16 = require("item.partner_chip")
	local d17 = require("item.partner_skin")
	local d18 = require("item.fuwen_wave")
	local d19 = require("item.partner_skin_type")
	local d20 = require("item.partner_travel")
	local d21 = require("item.equip_wave")
	local d22 = require("item.ui_item")
	local d23 = require("item.equip_se")
	local d24 = require("item.equip_set")
	local d25 = require("item.parequip")
	local d26 = require("item.parstone")
	local d27 = require("item.parsoul")
	local d28 = require("item.fuwen_quality")
	local d29 = require("item.equip_set_name")
	local d30 = require("item.partner_chip_exchange")

	local s = table.dump(d1, "OTHER").."\n"..table.dump(d2, "VIRTUAL").."\n"..table.dump(d3,"EQUIP").."\n"..
			  table.dump(d5,"EQUIPSTONE").."\n"..table.dump(t_d6,"FUWEN").."\n"..table.dump(d7,"GEM").."\n"..
			  table.dump(t_d9,"STRENGTH").."\n"..table.dump(d10,"GEM_LEVEL").."\n"..
			  table.dump(d12, "HOUSE").."\n"..table.dump(d13,"PARTNER_AWAKE").."\n"..table.dump(d14, "SCHOOL_WEAPON").."\n"..
			  table.dump(d15, "MODULE_SRC").."\n"..table.dump(d16, "PARTNER_CHIP").."\n"..table.dump(d17, "PARTNER_SKIN").."\n"..
			  table.dump(d18, "FUWEN_WAVE").."\n"..table.dump(d19, "PARTNER_SKIN_TYPE").."\n"..table.dump(d20, "PARTNER_TRAVEL").."\n"..
			  table.dump(d21, "EQUIP_WAVE").."\n"..table.dump(d22, "UI_ITEM").."\n"..table.dump(d23, "EQUIP_SE").."\n"..table.dump(d24, "EQUIP_SET").."\n"..
			  table.dump(d25, "PAR_EQUIP").."\n"..table.dump(d26, "PAR_STONE").."\n"..table.dump(d27, "PAR_SOUL").."\n"..table.dump(d28, "FUWEN_ATTR_WAVE").."\n"..
			  table.dump(d29, "EQUIP_SET_NAME").."\n".. table.dump(d30, "PARTNER_CHIP_EXCHANGE")
	SaveToFile("item", s)
end
