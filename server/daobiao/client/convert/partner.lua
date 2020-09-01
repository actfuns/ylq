module(..., package.seeall)
function main()
	local t = {}
	local d1 = require("partner.partner_info")
	table.insert(t, table.dump(d1, "DATA"))
	
	local d2 = require("partner.upgrade_star")
	table.insert(t, table.dump(d2, "UPSTAR"))
	
	
	local d3 = require("partner.cost_formula")
	table.insert(t, table.dump(d3, "COST"))
	
	local d4 = require("partner.partner_upgrade")
	table.insert(t, table.dump(d4, "UPGRADE"))
	
	local d11 = require("partner.star_partner_upgrade")
	table.insert(t, table.dump(d11, "STARUPGRADE"))

	local d5 = require("item.partner_chip")
	table.insert(t, table.dump(d5, "CHIP"))
	
	local d6 = require("item.awake_item")
	table.insert(t, table.dump(d6, "AWAKEITEM"))
	
	local d7 = require("partner.eat_exp")
	table.insert(t, table.dump(d7, "EATEXP"))
	
	local d8 = require("partner.wuling_card")
	table.insert(t, table.dump(d8, "WULINGCARD"))
	
	local d9 = require("partner.wuhun_card")
	table.insert(t, table.dump(d9, "WUHUNCARD"))
	
	local d10 = require("partner.partner_attr")
	table.insert(t, table.dump(d10, "ATTR"))
	
	local d12 = require("partner.bullet_config")
	table.insert(t, table.dump(d12, "BulletConfig"))

	local d = require("partner.partner_rare")
	table.insert(t, table.dump(d, "ComposeCost"))

	SaveToFile("partner", table.concat(t, "\n"))

	local d13 = require("partner.partnerchat")
	local dchat = {}
	for _, v in ipairs(d13) do
		dchat[v.partner_type] = dchat[v.partner_type] or {}
		dchat[v.partner_type][v.scene_id] = v
	end
	
	local s13 = table.dump(dchat, "PartnerChat")
	SaveToFile("partnerchat", s13)

	local d14 = require("partner.partner_gonglue")
	local s14 = table.dump(d14, "PartnerGongLue")

	local d15 = require("partner.partner_recommend")
	local s15 = table.dump(d15, "PartnerRecommend")

	local d16 = require("partner.partner_source")
	local s16 = table.dump(d16, "PartnerSource")

	SaveToFile("partnerrecommend", s14.."\n"..s15.."\n"..s16)

	local dSkin = require("partner.skinsize")
	local sSkin = table.dump(dSkin, "PartnerSkinSize")
	SaveToFile("partnerskinsize", sSkin)

	local dBook = require("partner.partnerbook")
	local sBook = table.dump(dBook, "PartnerBookConfig")
	SaveToFile("partnerbook", sBook)

	local dHire = require("partner.partner_hire")
	local sHire = table.dump(dHire, "DATA")

	local dHireConfig = require("partner.hire_config")
	local sHireConfig = table.dump(dHireConfig, "Config")
	SaveToFile("partnerhire", sHire.."\n"..sHireConfig)

	local dAwakeList = {}
	local t = require("partner.awake_attr")
	table.insert(dAwakeList, table.dump(t, "AwakeAttr"))
	
	local t = require("partner.awake_before")
	table.insert(dAwakeList, table.dump(t, "Level"))

	local t = require("partner.awake_after")
	table.insert(dAwakeList, table.dump(t, "AwakeLevel"))
	SaveToFile("partnerawake", table.concat(dAwakeList, "\n"))
end
