module(..., package.seeall)

function main()
	local dDirection = require("achieve.direction")
	local dAchieve = require("achieve.achieve")
	local dRewardPoint = require("achieve.reward_point")
	local lDirection = {}
	for k,v in pairs(dDirection) do
		lDirection[k] = v
		lDirection[k].sum_point = 0
	end

	for k,v in pairs(dAchieve) do
		if v.maxtype and v.maxtype == 1 then
			v.condition = v.maxtype
		elseif v.condition then
			for out in string.gmatch(v.condition, "(%w+)") do
				v.condition = tonumber(out)
			end
		end
		v.direction = tonumber(v.direction)
		lDirection[v.direction].sum_point = lDirection[v.direction].sum_point + v.point
	end

	--成就分支：七天目标
	local d1 = require("achieve.sevenday")
	local d2 = require("achieve.sevenday_point")
	local d3 = require("achieve.sevenday_gift")
	for k,v in pairs(d1) do
		if v.condition then
			--for out in string.gmatch(v.condition, "(%w+)") do
			--	v.condition = tonumber(out)
			--end
			v.direction = nil
		end
		--v.direction = tonumber(v.direction)
	end
	for k,v in pairs(d2) do
		if v.rewarditem then
			v.rewarditem = nil
		end
	end
	for k,v in pairs(d3) do
		if v.rewarditem then
			v.rewarditem = nil
		end
	end
	
	local s = table.dump(lDirection, "DIRECTION").."\n"..table.dump(dRewardPoint, "REWARDPOINT").."\n"..table.dump(dAchieve, "ACHIEVE")
		.."\n"..table.dump(d1, "SevenDayTarget").."\n"..table.dump(d2, "SevenDayTarget_Point").."\n"..table.dump(d3, "SevenDayTarget_Gift")
	SaveToFile("achieve", s)
end