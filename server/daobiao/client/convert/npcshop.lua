module(..., package.seeall)
function main()
	local d = require("store.npcstore")
	local d1 = require("store.coin_type")
	local d2 = require("store.storepage")
	local d3 = require("store.storetag")
	local d4 = require("item.itemvirtual")
	local d5 = require("store.currency_guide")
	local d6 = require("store.get_way")
	local d7 = require("store.rechargestore")
	local d8 = require("store.random_talk")
	local d9 = require("store.recharge_qq")

	--商品数据
	local d_out = {}
	for k,v in pairs(d) do
		d_out[k] = {}
		d_out[k].id = v.id
		if v.name ~= "" then
			d_out[k].name = v.name
		end
		if v.icon ~= 0 then
			d_out[k].icon = v.icon
		end
		if v.description ~= "" then
			d_out[k].description = v.description
		end
		d_out[k].item_id = v.item_id
		d_out[k].coin_typ = v.coin_typ
		d_out[k].coin_count = v.coin_count
		d_out[k].sortId = v.sortId
		d_out[k].cycle_type = v.cycle_type
		d_out[k].mark = v.mark
		d_out[k].vip = v.vip
		d_out[k].recharge = v.recharge
		d_out[k].payid = v.payid
		d_out[k].iospayid = v.iospayid
		if v.grade_limit.max ~= nil or v.grade_limit.min ~= nil then
			d_out[k].grade_limit = v.grade_limit
		end
		if v.item_arg ~= "" then
			d_out[k].item_arg = v.item_arg
		end
	end

	local function d_sortFunc(v1, v2)
		return d[v1].sortId < d[v2].sortId
	end
	--商品展示顺序
	local d_sort = {}
	for k,v in pairs(d) do
		d_sort[v.shop_id] = d_sort[v.shop_id] or {}
		table.insert(d_sort[v.shop_id], v.id)
	end
	for k,v in pairs(d_sort) do
		table.sort(v, d_sortFunc)
	end

	--商店页展示顺序
	local d2_out = {}
	for k,v in pairs(d2) do
		table.insert(d2_out, v.id)
		for i = 1, #v.subId do
			d3[v.subId[i]].storepage = v.id
		end
	end
	local function d2_sortFunc(v1, v2)
		return d2[v1].sortId < d2[v2].sortId
	end
	table.sort(d2_out, d2_sortFunc)

	--虚拟货币图标
	for k,v in pairs(d1) do
		if d4[v.virtual_id] ~= nil then
			v.icon = tostring(d4[v.virtual_id].icon)
		else
			v.icon = ""
		end
	end

	-- local d9_out = {}
	-- for _,v in pairs(d9) do
	-- 	d9_out[v.channel_name] = d9_out[v.channel_name] or {}
	-- 	for __,sType in ipairs(v.game_type) do
	-- 		d9_out[v.channel_name][sType] = v.qq
	-- 	end
	-- end

	local s = table.dump(d_out, "DATA").."\n"..table.dump(d1, "Currency").."\n"..table.dump(d2, "StorePage").."\n"..table.dump(d3, "StoreTag")
	.."\n"..table.dump(d2_out, "PageSort").."\n"..table.dump(d_sort, "GoodsDataSort").."\n"..table.dump(d5, "CurrencyGuide")
	.."\n"..table.dump(d6, "GetWay").."\n"..table.dump(d7, "RechargeStore").."\n"..table.dump(d8, "RandomTalk").."\n"..table.dump(d9, "RechargeQQ")
	SaveToFile("npcstore", s)
end
