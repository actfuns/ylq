module(..., package.seeall)
function main()
	local d1 = require("huodong.welfare.fulireward")
	local d2 = require("huodong.welfare.total_recharge")
	local d3 = require("huodong.welfare.welfare_control")
	local d4 = require("huodong.dailysign.week")
	local d5 = require("huodong.dailysign.signtype")
	local d6 = require("huodong.welfare.first_charge")
	local d7 = require("huodong.rewardback.config")
	local d8 = require("huodong.welfare.consume_point")
	local d9 = require("huodong.welfare.luck_draw_reward")
	local d10 = require("huodong.welfare.recharge_score")
	local d11 = require("huodong.welfare.recharge_score_config")
	local d12 = require("huodong.charge.charge_reward")
	local d13 = require("huodong.charge.chargereward_open")
	local d14 = require("huodong.oneRMBgift.oneRMBgift")
	local d15 = require("huodong.addcharge.addcharge")
	local d16 = require("huodong.daycharge.daycharge")
	local d17 = require("huodong.welfare.consume_plan")
	local d18 = require("huodong.welfare.timelimit_resume")
	local d18_2 = require("huodong.welfare.timelimit_plan")
	local d19 = require("huodong.welfare.welfare_rank")
	local d20 = require("qqgift")

	local d19_out1 = {}
	local d19_out2 = {}
	for k,v in pairs(d19) do
		if v.rank_id == 103 then
			table.insert(d19_out1, v)
		elseif v.rank_id == 115 then
			table.insert(d19_out2, v)
		end
	end
	local function sort_d19_out1(v1, v2)
		return v1.range.lower < v2.range.lower
	end
	table.sort(d19_out1, sort_d19_out1)

	local s = table.dump(d1, "FuliReward") .. "\n" .. table.dump(d2, "TotalRecharge")
	 .. "\n" .. table.dump(d3, "WelfareControl")
	 .. "\n" .. table.dump(d4, "DailySign_Week") .. "\n" .. table.dump(d5, "DailySign_Type")
	 .."\n".. table.dump(d6, "FirstCharge")
	 .."\n".. table.dump(d7, "RewardBack")
	 .."\n".. table.dump(d8, "CostScoreData")
	 .."\n".. table.dump(d9, "LuckyDrawData")
	 .."\n".. table.dump(d10, "RechargeScoreData")
	 .."\n".. table.dump(d11, "RechargeScoreConfig")
	 .."\n".. table.dump(d12, "CHARGE_REWARD")
	 .."\n".. table.dump(d13, "CHARGE_REWARD_OPEN")
	 .."\n".. table.dump(d14, "YiYuanLiBao")
	 .."\n".. table.dump(d15, "RushRecharge")
	 .."\n".. table.dump(d16, "LoopPay")
	 .."\n".. table.dump(d17, "ConsumePlan")
	 .."\n".. table.dump(d18, "LimitPay")
	 .."\n".. table.dump(d18_2, "LimitPayPlan")
	 .."\n".. table.dump(d19_out1, "PowerRank")
	 .."\n".. table.dump(d19_out2, "PartnerRank")
	 .."\n".. table.dump(d20, "QQVip")
	SaveToFile("welfare", s)
end
