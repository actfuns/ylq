module(..., package.seeall)

function main()
	local d1 = require("huodong.treasure.normal")
	local d2 = require("huodong.treasure.distance")
	local d3 = require("huodong.treasure.eventtips")
	local sDesc =   "FARDESC=[[" .. d2[1].desc .. "]]".."\n"..
					"NEARDESC=[[" .. d2[2].desc .. "]]".."\n"..
					"HEREDESC=[[" .. d2[3].desc .. "]]".."\n"

	local ChangGui = {}
	local BaoDi = {}
	local Mid = {}
	local Stop = {}
	for k,v in pairs(d1) do
		if v.changgui and v.changgui ~= "" then
			table.insert(ChangGui, v.changgui)
		end

		if v.baodi and v.baodi ~= "" then
			table.insert(BaoDi, v.baodi)
		end

		if v.mid and v.mid ~= "" then
			table.insert(Mid, v.mid)
		end

		if v.stop and v.stop ~= "" then
			table.insert(Stop, v.stop)
		end
	end
	
	local s =   table.dump(ChangGui, "CHANGGUI").."\n"..
				table.dump(BaoDi, "BAODI").."\n"..
				table.dump(Mid, "MID").."\n"..
				table.dump(Stop, "STOP").."\n"..
				table.dump(d3, "EVENTTIPS")
	SaveToFile("treasure", sDesc.."\n"..s)
	--[[
	local treasure_reward = require("reward.treasure_reward")
	local treasure_itemreward = require("reward.treasure_itemreward")

	local reward = {}
	local backups = {}
	for i,v in pairs(treasure_reward) do
		reward[v.id] = {}
		if v.sid then
			reward[v.id].sid = v.sid
		end
		if v.name then
			reward[v.id].name = v.name
		end
		if v.desc then
			reward[v.id].desc = v.desc
		end
	end

	for i,v in pairs(treasure_itemreward) do
		if v.idx then
			backups[v.idx] = {}
			if v.sid then
				backups[v.idx].sid = v.sid
			end

			if v.amount then
				backups[v.idx].amount = v.amount
			end
			if v.bind then
				backups[v.idx].bind = v.bind
			end
		end
	end
		.. "\n" .. table.dump(reward, "REWARD").. "\n" .. table.dump(backups, "BACKUPS")
	]]
end
