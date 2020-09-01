module(..., package.seeall)
function main()
	local dOri = require("house.furniture")
	local d = {}
	for k, v in pairs(dOri) do
		if not d[v.furniture_type] then
			d[v.furniture_type] = {}
		end
		d[v.furniture_type][v.level] = v
	end
	-- local s1 = table.dump(d, "Upgrade")
	local d2 = require("house.housepartner")
	for k,v in pairs(d2) do
		v.birth = string.format("%s.%s", v.birth.month, v.birth.day)
	end
	-- local s2 = table.dump(d2, "HousePartner")

	local d3 = require("house.talent_gift")
	-- local s3 = table.dump(d3, "Talent")

	local d4 = require("house.houselove")
	-- local s4 = table.dump(d4, "HouseLove")

	local d5 = require("house.live2d_body")
	local d5_out = {}
	for k,v in pairs(d5) do
		if d5_out[v.partner_type] == nil then
			d5_out[v.partner_type] = {}
		end
		table.insert(d5_out[v.partner_type], v)
	end
	local function d5_out_sortFunc(v1, v2)
		return v1.sort_id < v2.sort_id
	end
	for k,v in pairs(d5_out) do
		table.sort(v, d5_out_sortFunc)
	end

	local d6 = require("house.love_stage")

	local d7 = require("house.furniture_type")

	local d8 = require("house.partner_train")
	local d8_out = {}
	for i,v in ipairs(d8) do
		d8_out[i] = v
		d8_out[i].timeS = v.time * 60
	end

	-- local d9 = require("house.dialog")
	-- local d9_out = {}
	-- for k, v in pairs(d9) do
	-- 	d9_out[v.dialog_id] = d9_out[v.dialog_id] or {}
	-- 	d9_out[v.dialog_id][v.subid] = v
	-- end

	local d10 = require("house.partner_task")
	local d10_out = {}

	local function d10_SortFunc(v1, v2)
		return v1.level < v2.level
	end
	for k,v in pairs(d10) do
		if d10_out[v.partner_type] == nil then
			d10_out[v.partner_type] = {}
		end
		table.insert(d10_out[v.partner_type], v)
	end
	for k,v in pairs(d10_out) do
		table.sort(v, d10_SortFunc)
	end

	local d11 = require("house.housedefines")
	d11.walk_speed.value = d11.walk_speed.value / 100
	local d12 = require("house.houseclothes")
	local d13 = require("house.housedialog")
	local d13_out = {}
	for k,v in pairs(d13) do
		if v.random == 1 then
			table.insert(d13_out, v.id)
		end
	end

	local d14 = require("house.partner_panel")
	local d15 = require("house.live2d_speak")
	local d16 = require("house.love_buff")
	local d17 = require("house.partner_love")
	local d17_out = {}
	for k,v in pairs(d17) do
		d17_out[v.type] = d17_out[v.type] or {}
		d17_out[v.type][v.stage] = {v.head[1].value, v.brease[1].value, v.gold_point[1].value, v.hand[1].value, v.leg[1].value}
	end

	local s = table.dump(d, "Upgrade").."\n"..table.dump(d2, "HousePartner").."\n"..table.dump(d3, "Talent").."\n"..table.dump(d4, "HouseLove")
	.."\n"..table.dump(d10_out, "HouseTask").."\n"..table.dump(d5_out, "Live2d_Body").."\n"..table.dump(d6, "Love_Stage").."\n"..table.dump(d7, "FurnitureType")
	.."\n"..table.dump(d8_out, "Train").."\n"..table.dump(d11, "HouseDefine").."\n"..table.dump(d12, "HouseClothes").."\n"..table.dump(d13_out, "HouseDialog")
	.."\n"..table.dump(d14, "PartnerPanel").."\n"..table.dump(d15, "Live2d_Speak").."\n"..table.dump(d16, "LoveBuff").."\n"..table.dump(d17_out, "PartnerLove")
	SaveToFile("house", s)
	-- SaveAllDataToFile("house", s1.."\n"..s3.."\n"..s4.."\n"..s4_out)
end
