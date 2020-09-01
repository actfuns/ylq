module(..., package.seeall)
function main()
	local d1 = require("system.org.org_grade")
	local d2 = require("system.org.member_limit")
	local d3 = require("system.org.contribute_type")
	local d4 = require("system.org.flag")
	local d5 = require("system.org.rule")
	local d6 = require("system.org.org_build")
	local d7 = require("system.org.org_sign_reward")
	local d8 = require("system.org.org_hongbao")
	local d9 = require("huodong.orgfuben.boss")
	local d10 = require("system.org.hongbao_ratio")
	local d11 = require("system.org.org_wish")
	local d12 = require("system.org.org_equip_wish")
	local d13 = require("system.org.hint")
	local d14 = require("huodong.orgfuben.fuben")

	local d4_out = {}
	for k,v in pairs(d4) do
		table.insert(d4_out, k)
	end
	local function d4_sortFunc(v1, v2)
		return v1 < v2
	end
	table.sort(d4_out, d4_sortFunc)

	local d12_out = {}
	for k,v in pairs(d12) do
		table.insert(d12_out, v.id)
	end
	local function d12_sortFunc(v1, v2)
		return d12[v1].sort_id < d12[v2].sort_id
	end
	table.sort(d12_out, d12_sortFunc)

	local orgFuBen = d9
	for k,v in pairs(d14) do
		if orgFuBen[v.boss] then
			orgFuBen[v.boss].level = v.level
		end
	end

	local s = table.dump(d1, "DATA").."\n"..table.dump(d2, "MemberLimit").."\n"..table.dump(d3, "Contribute")
	.."\n"..table.dump(d4, "Flag").."\n"..table.dump(d5, "Rule")..table.dump(d6, "Build")..table.dump(d7, "OrgSignReward")
	.."\n"..table.dump(d8, "RedBag").."\n"..table.dump(orgFuBen, "OrgFuBen").."\n"..table.dump(d10, "RedBagRatio")
	.."\n"..table.dump(d11, "Wish").."\n"..table.dump(d4_out, "FlagSort").."\n"..table.dump(d12, "EquipWish")
	.."\n"..table.dump(d12_out, "EquipWishSort").."\n"..table.dump(d13, "Hint")
	SaveToFile("org", s)
end
