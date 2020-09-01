module(..., package.seeall)
function main()
	local newTable = nil
	local oriTable = nil
	local itemReward = nil

	local npcNameList = {"test", "story", "shimen", "fengyao", "trapmine", "achieve", "pata", "equipfuben", "teach", "treasure", "orgfuben", "practice", "daily", "npcfight", "rewardback", "partner", "welfare", "charge"}
	for _,name in ipairs(npcNameList) do
		oriTable = require("reward." .. name .. "_reward")
		itemReward = require("reward." .. name .. "_itemreward")
		if next(oriTable) then
			for key,t in pairs(oriTable) do
				t.reward = t.reward or {}
				
				--equipfuben start			
				local equipfuben_base_reward_id = nil
				if t.item and #t.item == 1 then							
					equipfuben_base_reward_id = tonumber(t.item[1].idx)
				end			
				--equipfuben end
				
				for _,v in ipairs(itemReward) do
					if key == v.idx then
						t.reward = t.reward or {}
						table.insert(t.reward, v)					
					end
					
					if name == "story" or name == "teach" or name == "practice" or name == "daily" or name == "partner" then
						if t.item and next(t.item)then
							for _k, _v in pairs(t.item) do
								if _v.idx == v.idx then
									t.task_reward = t.task_reward or {}
									table.insert(t.task_reward, v)	
								end							
							end					
						end
												
					end
					
					if name == "pata" then
						if key == v.idx then
							t.first_reward = t.first_reward or {}
							table.insert(t.first_reward, v)					
						end
					end
					
					if name == "equipfuben"  then 
						t.base_reward = t.base_reward or {}										
						if equipfuben_base_reward_id and v.idx == equipfuben_base_reward_id then
							--if not string.find(v.sid, "(") then
								local d = {}
								d.sid = v.sid
								d.amount = v.amount
								table.insert(t.base_reward, d)
							--end						
						end				
					end
				end
			end
		else
			if name == "welfare" then
				oriTable = {}
				oriTable.reward = {}
				for _,v in pairs(itemReward) do
					oriTable.reward[v.idx] = {
						sid = v.sid,
						amount = v.amount,
					}
				end
			end
		end
		newTable = (newTable or "") .. "\n" .. table.dump(oriTable, string.upper(name))
	end
	SaveToFile("reward", newTable)
end