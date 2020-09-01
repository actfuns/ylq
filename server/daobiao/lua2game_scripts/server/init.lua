
local dumpapi = require "utils.datadump"

local sRootPath, sOutPath = ...
local M = {}

local function Require(sPath)
    local sFile = string.format("%s/%s.lua", sRootPath, sPath)
    local f, s = loadfile(sFile, "bt")
    assert(f, s)
    return f()
end

local function RequireIgnore(sPath)
    local sFile = string.format("%s/%s.lua", sRootPath, sPath)
    local f, s = loadfile(sFile, "bt")
	if  f then
		return f()
	end
end


local mPlayDaoBiao = {
    worldboss = {"playconfig","npc","event","text","choose","fight","monster","reward","scene",},
    fengyao = {"npc","event","text","choose","fight","monster","reward",},
    trapmine = {"npc","event","text","choose","fight","monster","reward","playconfig"},
    question = {"npc","event","text","choose","reward","scene"},
    arenagame = {"npc","event","text","choose","fight","monster","playconfig","reward"},
    upcard = {"playconfig",},
    charge = {"text","reward"},
    story = {"fight","monster","reward"},
    shimen = {"fight","monster","reward",},
    teach = {"reward"},
    test = {"fight","monster","reward"},
    endless_pve = {"fight","monster","reward", "playconfig"},
    pata = {"fight","monster","reward","text"},
    lilian = {"fight","monster","reward",},
    perform_summon = {"monster"},
    rank = {"reward",},
    equipfuben = {"text","scene","npc","monster","fight","event","reward","playconfig",},
    treasure = {"npc","event","reward","text"},
    globaltemple = {"reward"},
    game={"scene","reward"},
    pefuben = {"text","reward","monster","fight","playconfig",},
    minglei = {"npc","event","fight","monster","reward",},
    orgfuben = {"text","monster","fight","reward","playconfig"},
    loginreward = {"text", "npc", "event", "reward"},
    practice = {"fight","monster","reward"},
    equalarena = {"text","playconfig","reward"},
    npcfight = {"fight", "monster", "reward"},
    daily = {"fight","monster","reward"},
    terrawars = {"npc","text"},
    common = {"reward"},
    travel = {"reward", "playconfig"},
    yjfuben = {"fight","monster","reward","scene","npc","event","text"},
    sociality = {"sociality", "text","playconfig", "choose"},
    fieldboss = {"npc","event","reward","scene","fight","monster"},
    dailysign = {"dailysign",},
    partner = {"reward","fight","monster"},
    plot = {"plot",},
    onlinegift = {"reward",},
    rewardback = {"reward",},
    chapterfb = {"text","reward","fight","monster"},
    teampvp = {"text","reward","playconfig","scene","npc"},
    convoy  ={"text","reward","fight","monster"},
    msattack = {"fight","monster","reward","npc","text","playconfig"},
    redeemcode = {"text"},
    welfare = {"text","reward"},
    orgwar = {"scene","npc","event","text","reward"},
    dailytrain = {"fight","monster","reward",},
    clubarena = {"text","monster","fight","playconfig","reward",},
    herobox = {"npc","text"},
    marry = {"text"},
    gradegift = {"text"},
    oneRMBgift = {"text"},
    addcharge ={"text"},
    daycharge ={"text"},
}


local function GetPlayDaoBiaoListByType(sType)
	local mData = {}
	for sKey,mList in pairs(mPlayDaoBiao) do
		for _,sVal in ipairs(mList) do
			if sVal == sType then
				table.insert(mData,sKey)
			end
		end
	end
	return mData
end



local function RequireItem()
    local mFile = {"itemother","itemvirtual","equip","equipstone","gem","housegift",
                            "awake_item", "partner_chip", "partner_skin",
                            "partner_travel","itemgifbag", "parequip", "parstone", "parsoul",}
    local ret = {}
    for _,sFile in pairs(mFile) do
        local m = Require(string.format("item/%s",sFile))
        for id,mData in pairs(m) do
            ret[id] = mData
        end
    end
    return ret
end

local function RequireFuwen()
    local mRet = {}
    local m = Require("item/fuwen")
    for _, mData in pairs(m) do
        local mPos = mRet[mData.equip_pos] or {}
        local iLevel = mData.level
        if not mPos[iLevel] then
            mPos[iLevel] = {}
        end
        mPos[iLevel] = mData
        mRet[mData.equip_pos] = mPos
    end

    return mRet
end

local function RequireFuwenQuality()
    local mRet = {}
    local mData = Require("item/fuwen_quality")
    for _, m in pairs(mData) do
        local iLevel = m.level
        local mQuality = mRet[m.quality] or {}
        mQuality[iLevel] = m
        mRet[m.quality] = mQuality
    end

    return mRet
end

local function RequireTaskDialog(sPath)
    local sFile = string.format("%s/%s.lua",sRootPath,sPath)
    local f,s = loadfile(sFile,"bt")
    assert(f,s)
    local m = f()
    local ret = {}
    local mDialog = {}
    for _,mData in pairs(m) do
        local dialog_id = mData["dialog_id"]
        local sub_id = mData["subid"]
        if not mDialog[dialog_id] then
        	mDialog[dialog_id] = {}
        end
        mDialog[dialog_id][sub_id] = {subid = sub_id,type=mData["type"],pre_id_list=mData["pre_id_list"],content=mData["content"],voice=mData["voice"],ui_mode = mData["ui_mode"],next = mData["next"],last_action = mData["last_action"],status = mData["status"],sub_talker_list = mData["sub_talker_list"]}
        mDialog[dialog_id][sub_id]["finish_event"] = mData["finish_event"]
    end
    for dialog_id,mData in pairs(mDialog) do
        ret[dialog_id] = {
            id = dialog_id,
            Dialog = mData
        }
    end
    return ret
end

local function RequireItemReward(sPath)
    local sFile = string.format("%s/%s.lua",sRootPath,sPath)
    local f,s = loadfile(sFile,"bt")
    assert(f,s)
    local m = f()
    local mRet = {}
    for _,mData in pairs(m) do
        local iRewardIdx = mData["idx"]
		_AssertItem(mData["sid"],string.format("file:%s,rewardid:%d",sFile,iRewardIdx))
        if mData.amount > 1000 or mData.amount <= 0 then
            local sExcel = "excel/" .. sPath .. ".xlsx"
            assert(false, string.format("xlsx:%s,item id:%s,amount:%s,overflow", sExcel, iRewardIdx, mData.amount))
        end
        local iGrade = mData["grade"] or 1
        if not mRet[iRewardIdx] then
            mRet[iRewardIdx] = {}
        end
        if not mRet[iRewardIdx][iGrade] then
            mRet[iRewardIdx][iGrade] = {}
        end
        table.insert(mRet[iRewardIdx][iGrade],mData)
    end
    return mRet
end



local function RequireNPCStore(sPath)
    local sFile = string.format("%s/%s.lua", sRootPath, sPath)
    local f, s = loadfile(sFile, "bt")
    assert(f, s)
    local m = f()
    local index = {}
	local mPEquip = {} -- 203商店符文索引
    local maketime = function (datastring)
        --2017-20-35 16:23
        local pattern=("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
        local year,month,day,hour,minute=datastring:match(pattern)
        return os.time({year=year,month=month,day=day,hour=hour,min=minute,sec=0})
        end
	local getitem = function(item_id)
		local mItem = M.item
		return mItem[item_id]
	end
    for id, mData in pairs(m) do
        local iShopId = mData.shop_id
        index[iShopId] = index[iShopId] or {}
		if iShopId == 203 then
			--mPEquip[mData.item_id] = id
			-- local mItem = getitem(mData.item_id)
			-- local iStar = mItem["equip_star"]
			-- if not mPEquip[iStar] then
			-- 	mPEquip[iStar] = {}
			-- end
			-- table.insert(mPEquip[iStar],id)
		end
        table.insert(index[iShopId], id)
        local mRebateTime = mData.rebate_time
        local sStart,sEnd = mRebateTime["start"],mRebateTime["over"]
        local iStart,iEnd = 0,0
        if sStart and sEnd and #sStart>0 and #sEnd>0 then
            iStart,iEnd = maketime(sStart),maketime(sEnd)
        end
        if iStart > 0 and iEnd>0 then
            mRebateTime["start"] = iStart
            mRebateTime["over"] = iEnd
        end
    end
    return {data = m, index = index,partner_equip = mPEquip}
end

local function RequireShop()
	local mFile = {refresh_count=1}
	local mRule = {}
	for sFile,sType in pairs(mFile) do
		local mData = Require(string.format("store/%s",sFile))
		for id,m in pairs(mData) do
			m["type"] =  sType
			assert(not mRule[id],"err rule")
			if sFile == "refresh_count" then
				local mClockList = m["reset_time"]
				table.sort(m["reset_time"],function (x,y) return x > y end)
			end
			mRule[id] = m
		end
	end
	local mShop = Require("store/storetag")
	return {rule = mRule,shop=mShop,npcstore =RequireNPCStore("store/npcstore")}
end

local function RequirePerform()
    local mPath = {"school","partner_perform","npc","se","equip"}
    local mData = {}
    for _,sPath in pairs(mPath) do
        local sFile = string.format("%s/perform/%s.lua",sRootPath,sPath)
        local f,s = loadfile(sFile,"bt")
        assert(f,s)
        local m = f()
        for id,mPerformData in pairs(m) do
			if mPerformData["ai_canperform"] then
				if mPerformData["ai_canperform"] == "" then
					mPerformData["ai_canperform"] = nil
				else
					local f = load(string.format("return %s",mPerformData["ai_canperform"]))
					mPerformData["ai_canperform"] = f()
				end
			end
        	mData[id] = mPerformData
        end
    end
    return mData
end

local function RequireTaskExtra(m)
    local mExtraFile = {
        ["lilian"] = {"fight"},
        ["teach"] = {"progress_reward"},
        ["partner"] = {"config"},
        ["dailytrain"] = {"fight"},
    }
    for sTask,value in pairs(mExtraFile) do
        m[sTask] = m[sTask] or {}
        for _,sFile in pairs(value) do
            local sPath = string.format("%s/task/%s/%s",sRootPath,sTask,sFile)
            m[sTask][sFile] = Require(string.format("task/%s/%s",sTask,sFile))
        end
    end
    return m
end

local function RequireTaskConfig(m)
    m["config"] = Require(string.format("task/%s","config"))
    m["guidance"] = Require(string.format("task/%s","guidance"))
    m["errortask"] = Require(string.format("task/%s","errortask"))
    return m
end

local function RequireTaskType(m)
	m["tasktype"] = Require(string.format("task/%s","tasktype"))
    return m
end

local function RequireTask()
    local mTaskList = {"story","test","shimen","lilian","teach","huodong","practice","daily","plot","partner","dailytrain"}
    local mFileList = {"task","taskdialog","tasktext","taskevent","tasknpc","taskitem","taskpick"}
    local m = {}
    for _,sTask in pairs(mTaskList) do
        m[sTask] = {}
        for _,sFile in pairs(mFileList) do
            local sPath = string.format("%s/task/%s/%s",sRootPath,sTask,sFile)
            if sFile == "taskdialog" then
                m[sTask][sFile] = RequireTaskDialog(string.format("task/%s/%s",sTask,sFile))
            else
                m[sTask][sFile] = Require(string.format("task/%s/%s",sTask,sFile))
            end
        end
    end
    m = RequireTaskExtra(m)
    m = RequireTaskConfig(m)
    m = RequireTaskType(m)
    return m
end

local function RequirePlayConfig()
	local mFile = GetPlayDaoBiaoListByType("playconfig")
	local mRequire = {}
	for _,sConfig in ipairs(mFile) do
		local m = RequireIgnore(string.format("playconfig/%s",sConfig)) or {}
		local mConfig = {}
		for sName,mData in pairs(m) do
			local sType = mData.valtype
			local val = mData.val
			if sType == "int" then
				val = tonumber(val)
			elseif sType == "table" then
				local f = load(string.format("return %s",val))
				val = f()
			end
			mConfig[sName] = val
		end
		mRequire[sConfig] = mConfig
	end
	return mRequire
end

local function RequirePlayBoyReward()
    local mData = Require("huodong/treasure/playboy_reward")
    local temp = {special = {},normal={}}
    for _,value in pairs(mData) do
        if value.type == 1 then
            table.insert(temp.normal,value)
        elseif value.type == 2 then
            table.insert(temp.special,value)
        end
    end
    return temp
end

local function RequireHeroBoxPool()
    local mData = Require("huodong/herobox/item_pool")
    local m = {}
    for _,info in pairs(mData) do
        m[info["type"]] = m[info["type"]] or {}
        m[info["type"]]["totalweight"] = (m[info["type"]]["totalweight"] or 0) + info["weight"]
        table.insert(m[info["type"]],info)
    end
    return m
end

local function RequireMingleiNpcPool()
    local mData = Require("huodong/minglei/config_npc")
    return mData
end

local function RequireMingleiFightPool()
    local mData = Require("huodong/minglei/config_fight")
    local m = {}
    for npcid,info in pairs(mData) do
        local tmp = {}
        for _,info in pairs(info["war_pool"]) do
            tmp[info["type"]] = tmp[info["type"]] or {}
            table.insert(tmp[info["type"]],info["fightid"])
        end
        m[npcid] = tmp
    end
    return m
end

local function RequireTrapmine()
    local mPool = {}
    local m = Require("huodong/trapmine/monster_pool")
    for _, mData in pairs(m) do
        if not mPool[mData.map_id] then
            mPool[mData.map_id] = {}
        end
        mPool[mData.map_id][mData.type] = mData
    end
    return mPool
end

local function RequireHuodongExtra(sName, mContent)
    local mHuodong = {
        ["treasure"] = {"normal_reward","baodi_reward","legend_reward",playboy_reward = RequirePlayBoyReward,"playboy_cost","dialog","legendconfig"},
        ["minglei"] = {"dialog","fight",config_npc=RequireMingleiNpcPool,config_fight = RequireMingleiFightPool},
        ["npcfight"] = {"dialog",},
        ["terrawars"] = {"terraconfig"},
        ["travel"] = {"travel","reward_pool", "travel_type", "travel_game", "dialog"},
        ["sociality"] = {"sociality",},
        ["fieldboss"] = {"fieldboss_config","dialog"},
        ["yjfuben"] = {"other","bossdesc","gradelimit","doubling"},
        ["dailysign"] = {"week","signtype"},
        ["onlinegift"] = {"onlinegift"},
        ["convoy"] = {"convoy_pool","config","dialog","fight_pool","follow_talk"},
        ["charge"] = {"grade_gift","card","privilege","gift_bag","chargereward_open"},
        ["msattack"] = {"basecontrol","refresh","expconfig","rank_reward","defense_reward"},
        ["shimen"] = {"dialog","config","taskpool"},
        ["teampvp"] = {"dialog",},
        ["trapmine"] = {"dialog","common_tollgate",monster_pool = RequireTrapmine,"rare_monster", "box_monster"},
        ["worldboss"] = {"dialog",},
        ["dailytrain"] = {"dialog","auto_skill"},
        ["hunt"] = {"config","soultype_config"},
        ["herobox"] = {"config",item_pool = RequireHeroBoxPool,"hero_pool"},
        ["virtualchat"] = {"config","chuanwen_pool"},
        ["gradegift"] = {"grade_gift"},
        ["oneRMBgift"] = {"oneRMBgift"},
        ["addcharge"] = {"addcharge"},
        ["daycharge"] = {"daycharge"},
        ["welfare"] = {"fulireward"},
        ["redeemcode"] = {"duihuan"},
    }
    if not mHuodong[sName] then
        return nil
    end

    for k, v in pairs(mHuodong[sName]) do
        local sFile, fParse
        if type(k) == "number" then
            sFile = v
        else
            sFile = k
            fParse = v
        end
        local mData
        if type(fParse) == "function" then
            mData = fParse()
        else
            mData = Require(string.format("huodong/%s/%s",sName,sFile))
        end
        mContent[sFile] = mData
    end
end

function RequireChargeReward(sHuodong,mHuodong)
    local sFile = "charge_reward"
    local sName = string.format("huodong/%s/%s",sHuodong,sFile)
    local mData = Require(sName)
    local mRet = {}
    for _,m in pairs(mData) do
        local iSchdule = m["schedule_id"]
        local iRmb = m["charge_rmb"]
        if not mRet[iSchdule] then
            mRet[iSchdule] = {}
        end
        mRet[iSchdule][iRmb] = m
    end
    mHuodong[sFile] = mRet
end

function RequireHuodongEquip(sHuodong,mHuodong)
	local mFile = {"fuben","floor","config","reset_cost"}
	for _,sFile in ipairs(mFile) do
		local mData = Require(string.format("huodong/%s/%s",sHuodong,sFile))
		mHuodong[sFile] = mData

	end
end

function RequireChapterFb(sHuodong,mHuodong)
    mHuodong["config"] = {}
    mHuodong["starreward"] = {}
    local mConfig = Require(string.format("huodong/%s/%s",sHuodong,"chapterfb"))
    for _,info in pairs(mConfig) do
        local iChapter = info["chapterid"]
        local iLevel = info["level"]
        mHuodong["config"][iChapter.."-"..iLevel] = mHuodong["config"][iChapter.."-"..iLevel] or {}
        table.insert(mHuodong["config"][iChapter.."-"..iLevel],info)
    end
    local mStarReward = Require(string.format("huodong/%s/%s",sHuodong,"starreward"))
    local tmp = {}
    for _,info in pairs(mStarReward) do
        tmp[info.chapterid] = tmp[info.chapterid] or {}
        tmp[info.chapterid][info.index] = tmp[info.chapterid][info.index] or {}
        tmp[info.chapterid][info.index][info.type] = {star=info.star,star_reward = info.star_reward}
    end
    mHuodong["starreward"] = tmp
end

function RequirePEFuben(sHuodong,mHuodong)
	local mFile = {"fuben","floor","reset_cost","floor_config"}
	for _,sFile in ipairs(mFile) do
		local mData = Require(string.format("huodong/%s/%s",sHuodong,sFile))
		if sFile == "fuben" then
			for iFB,mFb in pairs(mData) do
				local mEquip = {}
				local mPart = {}
				local mRewardEquip = {}
				local mRewardPart = {}
				for _,m in pairs(mFb["equip_ratio"]) do
					mEquip[m["equip"]] = m["ratio"]
				end
				for _,m in pairs(mFb["part_ratio"]) do
					mPart[m["part"]] = m["ratio"]
				end
				for _,m in pairs(mFb["reward_equip_ratio"]) do
					mRewardEquip[m["equip"]] = m["ratio"]
				end
				for _,m in pairs(mFb["reward_part_ratio"]) do
					mRewardPart[m["part"]] = m["ratio"]
				end
				mFb["equip_ratio"] = mEquip
				mFb["part_ratio"] = mPart
				mFb["reward_equip_ratio"] = mRewardEquip
				mFb["reward_part_ratio"] = mRewardPart
			end
		end
		mHuodong[sFile] = mData
	end
end


function RequireOrgFuben(sHuodong,mHuodong)
	local mFile = {"fuben","boss","cost_fuben"}
	for _,sFile in ipairs(mFile) do
		local mData = Require(string.format("huodong/%s/%s",sHuodong,sFile))
		mHuodong[sFile] = mData
	end
	return mHuodong
end

function RequireLoginReward(sHuodong, mHuodong)
    local lFile = {"reward",}
    for _, sFile in ipairs(lFile) do
        local mData = Require(string.format("huodong/%s/%s",sHuodong,sFile))
        mHuodong[sFile] = mData
    end
    return mHuodong
end

function RequireWorldboss(sHuodong, mHuodong)
    local lFile = {"buff","bossfight","expconfig","reward",}
    for _, sFile in ipairs(lFile) do
        local mData = Require(string.format("huodong/%s/%s",sHuodong,sFile))
		if sFile == "reward" then
			mHuodong["boss_reward"] = mData
		else
			mHuodong[sFile] = mData
		end
    end
    return mHuodong
end

function RequireEqualarena(sHuodong, mHuodong)
    local lFile = {"arena","operate","partner","partner_equip","ratio_list","role","reward_config"}
    for _, sFile in ipairs(lFile) do
        local mData = Require(string.format("huodong/%s/%s",sHuodong,sFile))
		if sFile == "operate" then
			for k,v in pairs(mData) do
			local s = v["data"]
			local m = load(string.format("cmd = %s return cmd",s))
			mData[k]["data"] = m()
			end
			mHuodong[sFile] = mData
		elseif sFile == "ratio_list" then
			local mRatioList = {}
			for k,m in pairs(mData) do
				mRatioList[k] = {}
				for u,v in pairs(m["weight"]) do
					mRatioList[k][v["value"]] =v["weight"]
				end
			end
			mHuodong[sFile] = mRatioList
		else
			mHuodong[sFile] = mData
		end
    end
    return mHuodong
end


function RequireRewardBack(sHuodong, mHuodong)
    local lFile = {"config"}
    for _, sFile in ipairs(lFile) do
        local mData = Require(string.format("huodong/%s/%s",sHuodong,sFile))
		if sFile == "config" then
			local m = {}
			for k,v in pairs(mData) do
				m[v["name"]] = k
			end
			mHuodong[sFile] = {name2id=m,data=mData}
		end
	end
	return mHuodong
end

function RequireTeamPVP(sHuodong,mHuodong)
    local lFile = {"winreward","rank"}
    for _, sFile in ipairs(lFile) do
		local mData = Require(string.format("huodong/%s/%s",sHuodong,sFile))
		if sFile == "rank" then

		end
        mHuodong[sFile] = mData
	end
	return mHuodong
end

function RequireClubarena(sHuodong,mHuodong)
    local lFile = {"config","robot"}
    for _, sFile in ipairs(lFile) do
        local mData = Require(string.format("huodong/%s/%s",sHuodong,sFile))
        if sFile == "config" then
			for k,v in pairs(mData) do
				for _,s in ipairs({"cr_1","cr_2","cr_3","cr_4",}) do
					local m = load(string.format("return %s",v[s]))
					v[s] = m()
				end
			end
        end
        mHuodong[sFile] = mData
    end
    return mHuodong
end

local mExtraHuodongData={
equipfuben = RequireHuodongEquip,
pefuben = RequirePEFuben,
orgfuben = RequireOrgFuben,
loginreward = RequireLoginReward,
worldboss = RequireWorldboss,
equalarena = RequireEqualarena,
rewardback = RequireRewardBack,
chapterfb = RequireChapterFb,
teampvp = RequireTeamPVP,
clubarena = RequireClubarena,
charge = RequireChargeReward,
}


local function RequireHuodong()
    local mFileList = {"npc","event","text","choose","scene",}
    local m = {}
    for _,sFile in ipairs(mFileList) do
        local mHDList = GetPlayDaoBiaoListByType(sFile)
        for _,sHuodong in ipairs(mHDList) do
        	if not m[sHuodong] then
        	   m[sHuodong] = {}
        	end
        	m[sHuodong][sFile] = Require(string.format("huodong/%s/%s",sHuodong,sFile))
        end
    end
    local mExtraFile = {"treasure","minglei","npcfight","terrawars", "travel", "travel_game", "sociality","fieldboss","yjfuben", "dailysign","onlinegift",
                                    "convoy","charge","msattack","shimen","teampvp", "trapmine","worldboss","dailytrain","hunt","herobox","virtualchat",
                                    "gradegift","oneRMBgift", "addcharge", "daycharge","welfare","redeemcode"}
    for _,sHuodong in pairs(mExtraFile) do
        m[sHuodong] = m[sHuodong] or {}
        RequireHuodongExtra(sHuodong, m[sHuodong])
    end
    for sHuodong,func in pairs(mExtraHuodongData) do
        m[sHuodong] = m[sHuodong] or {}
        func(sHuodong,m[sHuodong])
    end

    return m
end






local function RequireFight()
    local mFile = GetPlayDaoBiaoListByType("fight")
    local m = {}
    for _,sName in ipairs(mFile) do
        local sPath = string.format("tollgate/%s",sName)
        m[sName] = Require(sPath)
    end
    return m
end

local function RequireMonster()
    local mFile = GetPlayDaoBiaoListByType("monster")
    local m = {}
    for _,sName in ipairs(mFile) do
        local sPath = string.format("monster/%s",sName)
        m[sName] = Require(sPath)
		for idx,mMonster in pairs(m[sName]) do
			for _,mP in ipairs(mMonster["activeSkills"] or {}) do
				_AssertPerformSkill(mP["pfid"],string.format("%s : %s",sPath,"activeSkills"))
			end
			for _,mP in ipairs(mMonster["passiveSkills"] or {}) do
				_AssertPerformSkill(mP["pfid"],string.format("%s : %s",sPath,"passiveSkills"))
			end
			for _,mP in ipairs(mMonster["special_skill"] or {}) do
				_AssertPerformSkill(mP["pfid"],string.format("%s : %s",sPath,"special_skill"))
			end
		end
    end
    return m
end

local function RequireRewardLimit(sPath)
    local mRet = {}
    local mData = RequireIgnore(sPath)
	if not mData then return end
    for _, mInfo in pairs(mData) do
        mRet[mInfo.idx] = mInfo.limit
    end
    return mRet
end


local function RequireDayLimit(sPath)
    local mRet = {}
    local mData = RequireIgnore(sPath)
	if not mData then return end
    for _, mInfo in pairs(mData) do
        mRet[mInfo.sid] = mInfo.limit
    end
    return mRet
end

local function RequireFileReward(sName)
    local mReward = {"reward","itemreward","rewardlimit","daylimit"}
    local mLimitReward = {}
    mLimitReward.pata = true
	mLimitReward.equipfuben = true
	mLimitReward.pefuben = true
    local m = {}
    for _,sReward in pairs(mReward) do
        local sFile = string.format("%s_%s",sName,sReward)
        local sPath = string.format("reward/%s",sFile)
        if sReward == "itemreward" then
            m[sReward] = RequireItemReward(sPath)
        elseif sReward == "rewardlimit" then
			local mLimit = RequireRewardLimit(sPath)
			if mLimit then
				m[sReward] = mLimit
			end
		elseif sReward == "daylimit" then
			local mLimit = RequireDayLimit(sPath)
			if mLimit then
				m[sReward] = mLimit
			end
        else
            m[sReward] = Require(sPath)
        end
    end
    return m
end

local function RequireReward()
    local mDir = GetPlayDaoBiaoListByType("reward")
    local m = {}
    for _,sName in ipairs(mDir) do
        m[sName] = RequireFileReward(sName)
    end
    return m
end

local function RequireUpGrade()
    local mRet = {}
    local mOld = Require("role/upgrade")

    local iTotal = 0
    for k, v in pairs(mOld) do
        iTotal = iTotal + 1
    end

    local iPlayerExp = 0
    local iSummonExp = 0
    for i = 1, iTotal do
        assert(mOld[i], string.format("RequireUpGrade fail %d", i))
        iPlayerExp = iPlayerExp + mOld[i].player_exp
        iSummonExp = iSummonExp + mOld[i].summon_exp
        mRet[i] = {}
        mRet[i].id = mOld[i].id
        mRet[i].player_exp = iPlayerExp
        mRet[i].summon_exp = iSummonExp
        mRet[i].upvote_limit = mOld[i].upvote_limit
    end

    return mRet
end

local function RequireSkill()
    local mRet = {}
    local mDir = {"school","partner","se","npc","equip"}
	local Aif = function (sArg)
		if sArg == "" or not sArg then return  end
		local iType = 0
		local iBuffID = 0
		if not string.find(sArg,"%|") then
			iType = tonumber(sArg)
		else
			iType,iBuffID = string.match(sArg,"([^%|]+)%|([^%|]+)")
			iType = tonumber(iType)
			iBuffID = tonumber(iBuffID)
		end
		if iType and iBuffID and iType ~= 0 then
			return {[iType] = iBuffID}
		end
	end
    for _,sFile in pairs(mDir) do
        local m = Require(string.format("skill/%s",sFile))
        for _,mData in pairs(m) do
            local iSk = mData["skill_id"]
            local iLevel = mData["skill_level"] or 1
            if not mRet[iSk] then
                mRet[iSk] = {}
            end
			mData["ai_target"] = Aif(mData["ai_target"])
            mRet[iSk][iLevel] = mData
        end
    end
    return mRet
end




local function RequireAura()
	local mData = Require(string.format("perform/aura"))
	for _,m in pairs(mData) do
		for k,v in pairs(m) do

			if k== "args" or k == "attr_set" then
				if v ~= "" then
					local f = load(string.format("return %s",v))
					m[k] = f()
				else
					m[k] = {}
				end
				assert(m[k],string.format("err %s",m[k]))
			end

		end
	end
    return mData
end

local function RequireBuffEffect()
    local m = Require("perform/buff_effect")
    local ret = {}
    for _,mData in pairs(m) do
        local iBuff = mData["buff_id"]
        local iLevel = mData["skill_lv"]
        if not ret[iBuff] then
            ret[iBuff] = {}
        end
        ret[iBuff][iLevel] = mData
    end
    return ret
end

local function RequireCultivateSkill()
    local mRet = {}
    local m = Require("skill/cultivate")
    for _,mData in pairs(m) do
        local iSk = mData["skill_id"]
        local iLevel = mData["level"]
        if not mRet[iSk] then
            mRet[iSk] = {}
        end
        mRet[iSk][iLevel] = mData
    end
    return mRet
end

local function RequireText()
    -- 文本信息相关导表
    local mTable = {}

    -- start
    mTable.fengyao = "huodong/fengyao"
    mTable.trapmine = "huodong/trapmine"
    -- end

    local mData = {}
    for key, sUrl in pairs(mTable) do
        mData[key] = {}
        mData[key]["text"] = Require(string.format("%s/%s",sUrl,"text"))
        mData[key]["choose"] = Require(string.format("%s/%s",sUrl,"choose"))
    end
    return mData
end

local function RequireRoleAttr()
    local mFile = {"roleattr_a","roleattr_b","roleattr_c"}
    local ret = {}
    for iNo,sFile in ipairs(mFile) do
        local sPath = string.format("role/%s",sFile)
        local m = Require(sPath)
        ret[iNo] = m
    end
    return ret
end

local function RequireStrength()
    local m = Require("item/strength")
    local ret = {}
    for _,mData in pairs(m) do
        local iPos = mData["equipPos"]
        local iLevel = mData["level"]
        if not ret[iPos] then
            ret[iPos] = {}
        end
        ret[iPos][iLevel] = mData
    end
    return ret
end

local function RequireHouseFurniture()
    local m = Require("house/furniture")
    local ret = {}
    for _,mData in pairs(m) do
        local iType = mData["furniture_type"]
        local iLevel = mData["level"]
        if not ret[iType] then
            ret[iType] = {}
        end
        ret[iType][iLevel] = mData
    end
    return ret
end

local function RequireHousePartnerLove()
    local m = Require("house/partner_love")
    local ret = {}
    for _,mData in pairs(m) do
        local iType = mData["type"]
        local iStage = mData["stage"]
        if not ret[iType] then
            ret[iType] = {}
        end
        ret[iType][iStage] = mData
    end
    return ret
end

local function RequireHousePartnerTask()
    local lPartask = Require("house/partner_task")
    local mRet = {}
    for _, m in ipairs(lPartask) do
        local mPart = mRet[m.partner_type] or {}
        mPart[m.level] = m
        mRet[m.partner_type] = mPart
    end
    return mRet
end

local function RequirePartner()
    local mRet = {}
    local m = Require("partner/partner_info")
    for iParSid, mData in pairs(m) do
        for _, iSkill in ipairs(mData.skill_list or {}) do
            _AssertPerformSkill(iSkill, string.format("partner:%s.", iParSid))
        end
    end
    mRet["partner_info"] = m
    mRet["partner_awake"] = Require("partner/awake_attr")
    mRet["star"] = Require("partner/upgrade_star")
    mRet["wuling_card"] = Require("partner/wuling_card")
    mRet["wuhun_card"] = Require("partner/wuhun_card")
    -- mRet["first_card"] = Require("partner/first_card")
    mRet["wuling_rank_card"] = Require("partner/wuling_rank_card")
    mRet["wuhun_rank_card"] = Require("partner/wuhun_rank_card")
    mRet["convert_power"] =Require("partner/partner_convert_power")
    mRet["cost"] = Require("partner/cost_formula")
    mRet["rare"] = Require("partner/partner_rare")
    mRet["ouqi"] = Require("partner/ouqi_config")
    mRet["wuhun_baodi"] = Require("partner/wuhun_baodi")
    mRet["wuhun_reduce"] = Require("partner/wuhun_reduce")
    mRet["partner_hire"] = Require("partner/partner_hire")
    mRet["hire_config"] = Require("partner/hire_config")
    mRet["partner_gonglue"] = Require("partner/partner_gonglue")
    mRet["text"] = Require("partner/text")
    mRet["choose"] = Require("partner/choose")
    local mItemCard = {}
    local m = Require("partner/item_card")
    for _, mData in pairs(m) do
        if not mItemCard[mData.shape] then
            mItemCard[mData.shape] = {}
        end
        table.insert(mItemCard[mData.shape], mData)
    end
    mRet["item_card"] = mItemCard
    local m = Require("partner/card_star")
    mRet["star_weight"] = {}
    for sType,mm in pairs(m) do
        mRet["star_weight"][sType] = {}
        for k,v in pairs(mm["weight"]) do
            mRet["star_weight"][sType][v["star"]] = v["ratio"]
        end
    end

    local mExp = {}
    mRet["upgrade"] = mExp
    local mOld = Require("partner/partner_upgrade")
    local iTotal = 0
    for k, v in pairs(mOld) do
        iTotal = iTotal + 1
    end
    local iExp = 0
    for i=1, iTotal do
        iExp = iExp + mOld[i].partner_exp
        mExp[i] = {}
        mExp[i].id = mOld[i].id
        mExp[i].partner_exp = iExp
    end
    local mExp = {}
    mRet["star_upgrade"] = mExp
    local mOld = Require("partner/star_partner_upgrade")
    local iTotal = 0
    for k, v in pairs(mOld) do
        iTotal = iTotal + 1
    end
    local iExp = 0
    for i=1, iTotal do
        iExp = iExp + mOld[i].partner_exp
        mExp[i] = {}
        mExp[i].id = mOld[i].id
        mExp[i].partner_exp = iExp
    end
    local mAttr = {}
    mRet["partner_attr"] = mAttr
    local m = Require("partner/partner_attr")
    for _, mData in pairs(m) do
        local iType = mData.partner_type
        if not mAttr[iType] then
            mAttr[iType] = {}
        end
        if not mRet["partner_info"][iType] then
            assert(false,string.format("excel/partner/partner.partner_attr.xlsx error :partner:%s not exsit!", iType))
        end
        mAttr[iType][mData.star] = mData
    end

    local mSkillGuide = {}
    mRet["skill_guide"] = mSkillGuide
    local m = Require("partner/skill_guide")
    for _, mData in ipairs(m) do
        local iType = mData.partype
        if not mSkillGuide[iType] then
            mSkillGuide[iType] = {}
        end
        local iCount = mData.count
        mSkillGuide[iType][iCount] =  mData
    end


	local mUpcardInfo = Require("partner/upcard_info")
	local mUpcard_info = {}
	for _,d in pairs(mUpcardInfo) do
		local sR = d.rare
		local mData = {partnerlist = d.partner_list}
		if not mUpcard_info[d.group] then
			mUpcard_info[d.group]= {}
		end
		mUpcard_info[d.group][sR] = mData
	end


	mRet["upcard_info"]=mUpcard_info
	local mUpConfig = Require("partner/upcard_config")



	local mCommonCard = {}
	local mTimeCard = {}
    local maketime = function (datastring)
        --2017-20-35
        local pattern=("(%d+)-(%d+)-(%d+)")
        local year,month,day=datastring:match(pattern)
        return os.time({year=year,month=month,day=day,hour=0,min=0,sec=0})
        end


	for _,d in pairs(mUpConfig) do
		local sid = d.sid
		if d.rule == 1 then
			d.openday = nil
			mCommonCard[sid]=d
		elseif d.rule == 2 then
			local mTime = d.openday
			mTime["start"] = maketime(mTime["start"])
			mTime["over"] = maketime(mTime["over"])
			mTimeCard[sid] = d
		end
	end
	mRet["upcard_config"]={common=mCommonCard,time=mTimeCard}
    return mRet
end

local function RequirePartnerItem()
    local mRet = {}
    mRet["equip_star"] = Require("item/parequip_star")
    mRet["awake_item"] = Require("item/awake_item")
    mRet["travel"] = Require("item/partner_travel")
    mRet["stone"] = Require("item/parstone")
    mRet["stone_pos"] = Require("item/parstone_pos")
    mRet["soul_pos"] = Require("item/parsoul_pos")
    mRet["soul_set"] = Require("item/parsoul_set")
    mRet["soul_quality"] = Require("item/parsoul_quality")
    mRet["soul_attr"] = Require("item/parsoul_attr")

    local mSoulUpgrade = {}
    mRet["soul_upgrade"] = mSoulUpgrade
    for _, m in pairs(Require("item/parsoul_upgrade")) do
        local iQuality = m.quality
        if not mSoulUpgrade[iQuality] then
            mSoulUpgrade[iQuality] = {}
        end
        mSoulUpgrade[iQuality][m.level] = m
    end
    local iMaxEquipLevel = 15
    for _, mData in pairs(mSoulUpgrade) do
        local iExp = 0
        for i = 1, iMaxEquipLevel do
            assert(mData[i], string.format("RequireUpGrade fail %d", i))
            iExp = iExp + mData[i].upgrade_exp
            mData[i].upgrade_exp = iExp
        end
    end

    mRet["partner_chip"] = Require("item/partner_chip")
    local mType2Chip = {}
    for iChipSid, m in pairs(mRet["partner_chip"] or {}) do
        _AssertPartner(m.partner_type, "partner_chip:"..iChipSid)
        mType2Chip[m.partner_type] = iChipSid
    end
    mRet["partype2chip"] = mType2Chip
    mRet["partner_skin"] = Require("item/partner_skin")
	local mShape2Type = {}
	for _,m in pairs(mRet["partner_skin"]) do
		mShape2Type[m["shape"]] = m["partner_type"]
	end

	mRet["shape2type"] = mShape2Type

    return mRet
end

local function RequireSchoolWeanpon()
    local mRet = {}
    local mSchoolWeapon = {}
    local mWeaponSchool = {}
    local m = Require("item/schoolweapon")
    for _, mData in ipairs(m) do
        local iSchool = mData.school
        local iBranch = mData.branch
        if not mSchoolWeapon[iSchool] then
            mSchoolWeapon[iSchool] = {}
        end
        mSchoolWeapon[iSchool][iBranch] = mData
        mWeaponSchool[mData.weapon] = iSchool
    end

    mRet["weapon"] = mSchoolWeapon
    mRet["school"] = mWeaponSchool

    return mRet
end

local function RequireNpc()
    local mFile = {"global_npc","wizard"}
    local mRet = {}
    for _,sFile in pairs(mFile) do
        local sPath = string.format("npc/%s",sFile)
        local m = Require(sPath)
        for iKey,mData in pairs(m) do
            mRet[iKey] = mData
        end
    end
    return mRet
end

local function RequireRankReward()
    local mDir = {"grade","warpower","terrawars_orgunit"}
    local mOrg = {"terrawars_server"}
    local mRet = {}
    for _,sName in ipairs(mDir) do
        local sPath = "system/rank/" .. sName .. "_rank_reward"
        local mData = Require(sPath)
        local lRwd = {}
        mRet[sName] = lRwd
        for _index, m in pairs(mData) do
            for i = m.rank_range.lower, m.rank_range.upper do
                lRwd[i] = m.reward
            end
        end
    end
    for _,sName in ipairs(mOrg) do
        local sPath = "system/rank/" .. sName .. "_rank_reward"
        local mData = Require(sPath)
        mRet[sName] = Require(sPath)
    end
    return mRet
end

local function RequireRushRank()
    local mData = Require("system/rank/rushrank")
    local mRet = {}
    for _, m in ipairs(mData) do
        local m1 = mRet[m.rank_id] or {}
        local m2 = m1[m.subtype] or {}
        m2[m.rank] = m
        m1[m.subtype] = m2
        mRet[m.rank_id] = m1
    end
    return mRet
end

local function RequireOrg()
    local ret  = {}
    local mFileList = { "text", "choose", "org_grade","contribute_type","member_limit","flag","rule","org_build","org_hongbao","org_wish","org_sign_reward","hongbao_ratio","org_log","org_equip_wish","org_attr"}
    for _,sFile in pairs(mFileList) do
        ret[sFile] = Require(string.format("system/org/%s",sFile))
    end
    return ret
end

local function RequireTitle()
    local ret  = {}
    local mFileList = {"title"}
    for _,sFile in pairs(mFileList) do
        ret[sFile] = Require(string.format("system/title/%s",sFile))
    end
    return ret
end

local function RequireHongBao()
    local ret  = {}
    local mFileList = { "hb_config", "text"}
    for _,sFile in pairs(mFileList) do
        ret[sFile] = Require(string.format("chat/%s",sFile))
    end
    return ret
end

local function RequireEndlessPVE()
    local mRet = {}
    local mData = Require("huodong/endless_pve/endless_pve_info")
    local mInfo = {}
    mRet["endless_pve_info"] = mInfo
    for _, m in pairs(mData) do
        local iRing = m.ring
        if not mInfo[iRing] then
            mInfo[iRing] = {}
        end
        mInfo[iRing][m.mode] = m
    end
    mRet["mode_info"] = Require("huodong/endless_pve/mode_info")
    -- mRet["partner_chip_pool"] = Require("huodong/endless_pve/partner_chip_pool")
    -- mRet["refresh_info"] = Require("huodong/endless_pve/refresh_info")
    -- mRet["special_chip_pool"] = Require("huodong/endless_pve/special_chip_pool")
    return mRet
end

local function RequireRandomName()
	return Require("role/randomname")
end

local function RequireVirtualName()
    return Require("role/fakerandomname")
end

local function RequireLuckDraw()
    local ret  = {}
    local mFileList = { "luck_draw_main", "luck_draw_reward","luck_draw_item"}
    for _,sFile in pairs(mFileList) do
        ret[sFile] = Require(string.format("huodong/welfare/%s",sFile))
    end
    return ret
end

local function RequireRechargeScore()
    local m = {}
    m["config"] = Require("huodong/welfare/recharge_score_config")
    m["item_pool"] = Require("huodong/welfare/recharge_score")
    return m
end

local function RequireWelfareRushRank()
    local mRet ={}
    local mData = Require("huodong/welfare/welfare_rank")
    for id, m in pairs(mData) do
        local mRank = mRet[m.rank_id] or {}
        local mSub = mRank[m.subtype] or {}
        table.insert(mSub, m)
        mRank[m.subtype] = mSub
        mRet[m.rank_id] = mRank
    end
    return mRet
end


local function RequireLog()
    local mData = {}
    mData.test = Require("log/test")
    mData.mail = Require("log/mail")
    mData.org = Require("log/org")
    mData.pata = Require("log/pata")
    mData.item = Require("log/item")
    mData.arenagame = Require("log/arenagame")
    mData.worldboss = Require("log/worldboss")
    mData.shop = Require("log/shop")
    mData.friend = Require("log/friend")
    mData.task = Require("log/task")
    mData.player = Require("log/player")
    mData.title = Require("log/title")
    mData.online = Require("log/online")
    mData.account = Require("log/account")
    mData.coin = Require("log/coin")
    mData.analy = Require("log/analy")
    mData.equipfuben = Require("log/equipfuben")
    mData.pefuben = Require("log/pefuben")
    mData.orgfuben = Require("log/orgfuben")
    mData.partner = Require("log/partner")
    mData.skill = Require("log/skill")
    mData.equip = Require("log/equip")
    mData.minglei = Require("log/minglei")
    mData.treasure = Require("log/treasure")
    mData.schedule = Require("log/schedule")
    mData.chat =  Require("log/chat")
    mData.trapmine = Require("log/trapmine")
    mData.lilian = Require("log/lilian")
    mData.loginreward = Require("log/loginreward")
    mData.endlesspve = Require("log/endlesspve")
    mData.partner_equip = Require("log/partner_equip")
    mData.equalarena = Require("log/equalarena")
    mData.picture = Require("log/picture")
    mData.achieve = Require("log/achieve")
    mData.huodong = Require("log/huodong")
    mData.question = Require("log/question")
    mData.pay = Require("log/pay")
    mData.travel = Require("log/travel")
    mData.terrawars = Require("log/terrawars")
    mData.yjfuben = Require("log/yjfuben")
    mData.fieldboss = Require("log/fieldboss")
    mData.npcfight = Require("log/npcfight")
    mData.house = Require("log/house")
    mData.handbook = Require("log/handbook")
    mData.rewardback = Require("log/rewardback")
    mData.teampvp = Require("log/teampvp")
    mData.chapterfb = Require("log/chapterfb")
    mData.onlinegift = Require("log/onlinegift")
    mData.msattack = Require("log/msattack")
    mData.convoy = Require("log/convoy")
    mData.shimen = Require("log/shimen")
    mData.fuli = Require("log/fuli")
    mData.achievetask = Require("log/achievetask")
    mData.rank = Require("log/rank")
    mData.hirepartner = Require("log/hirepartner")
    mData.clubarena = Require("log/clubarena")
    mData.orgwar = Require("log/orgwar")
    mData.gradegift = Require("log/gradegift")
    mData.one_RMB_gift = Require("log/one_RMB_gift")
    mData.hd_add_charge = Require("log/hd_add_charge")
    mData.hd_day_charge = Require("log/hd_day_charge")
    mData.chargescore = Require("log/chargescore")
    mData.limitopen = Require("log/limitopen")
    mData.hd_rankback = Require("log/hd_rankback")
    return mData
end

local function RequireAchieve()
    local sPath= "achieve/%s"
    local mAchieve = Require(string.format(sPath,"achieve"))
    local mDirection = Require(string.format(sPath,"direction"))
    local mReward = Require(string.format(sPath,"reward_point"))
    local mPicture = Require(string.format(sPath,"picture"))
    local mSevenDay = Require(string.format(sPath, "sevenday"))
    local mSevenDayPoint = Require(string.format(sPath, "sevenday_point"))
    local mSevenDayGift = Require(string.format(sPath, "sevenday_gift"))
    local mAchieveTask = Require(string.format(sPath,"achievetask"))
    local mData = {}
    mData.configure = mAchieve
    mData.direction = mDirection
    mData.reward = mReward
    mData.picture = mPicture
    mData.sevenday = mSevenDay
    mData.sevenday_point = mSevenDayPoint
    mData.sevenday_gift = mSevenDayGift
    mData.achievetask = mAchieveTask
    return mData
end


local function RequireSchedule()
	local mName2ID = {}
	local sPath= "schedule/%s"
	local mData = {}
	local mPublic = Require(string.format(sPath,"public"))
	local mReward = Require(string.format(sPath,"activereward"))

	for iKey,m in pairs(mPublic) do
		local name = m.huodong
		if name ~= "" then
		mName2ID[name] = iKey
		end
	end
	mData.public = mPublic
	mData.activereward = mReward
	mData.name2id = mName2ID
	return mData
end

local function RequireRoleBranch()
    local mRet = {}
    local m = Require("role/branchtype")
    for _, mData in ipairs(m) do
        local iSchool = mData.school
        mRet[iSchool] = mRet[iSchool] or {}
        mRet[iSchool][mData.branch] = mData
    end
    return mRet
end

local function RequireArenaGame()
	local mData = {}
	mData["arena"] = Require("arena/arena")
	mData["top"] = Require("arena/reward_top")
	return mData
end

local function RequireHandbook()
    local mRet = {}
    mRet["condition"] = Require("handbook/condition")
    mRet["chapter"] = Require("handbook/chapter")
    local mHandbook = {}
    local mCondition = {}
    local mChapter = {}
    local lHandbook = {"partner", "person"}
    for _, sFile in ipairs(lHandbook) do
        local m = Require(string.format("handbook/%s", sFile))
        for id, mData in pairs(m) do
            mHandbook[id] = mData
            for _, iCnd in ipairs(mData.condition_list or {}) do
                assert(mRet["condition"][iCnd], string.format("handbook err:condition:%s not exsit!", iCnd))
                mCondition[iCnd] = mCondition[iCnd] or {}
                table.insert(mCondition[iCnd], id)
            end
            for _, iChapter in ipairs(mData.chapter_list or {}) do
                assert(mRet["chapter"][iChapter], string.format("handbook err:chapter:%s not exsit!", iChapter))
                mChapter[iChapter] = mChapter[iChapter] or {}
                table.insert(mChapter[iChapter], id)
            end
        end
    end
    for iChapter, mData in pairs(mRet["chapter"] or {}) do
        for _, iCnd in ipairs(mData.condition or {}) do
            assert(mRet["condition"][iCnd], string.format("handbook err:condition:%s not exsit!", iCnd))
            mCondition[iCnd] = mCondition[iCnd] or {}
            table.insert(mCondition[iCnd], iChapter)
        end
    end
    mRet["book"] = mHandbook
    mRet["condition_effect"] = mCondition
    mRet["chapter_effect"] = mChapter
    return mRet
end

local  function RequireTaskBarrage()
    local mData  =Require("task_barrage")
    local m = {}
    for k,info in pairs(mData) do
        m[info.show_id] = m[info.show_id] or {}
        table.insert(m[info.show_id],{msg=info.content,from_player = 0})
    end
    return m
end

local function RequirePay()
    local mRet = {}
    local mPayFile = {"pay","ios_pay"}
    for _,sFile in ipairs(mPayFile) do
        local m = Require(string.format("pay/%s",sFile))
        for id,mData in pairs(m) do
            mRet[id] = mData
        end
    end
    return mRet
end

function RequireEquipCompose()
    local mRet = {}
    local mData = Require('item/compose_equip')
    for _, m in pairs(mData) do
        local iPos = m.pos
        if not mRet[iPos] then
            mRet[iPos] = {}
        end
        mRet[iPos][m.grade] = m
    end
    return mRet
end

local function RequireAllChannel(mInfo)
    local lChannels = {}
    for id, mData in pairs(mInfo) do
        table.insert(lChannels, id)
    end
    return lChannels
end

local function RequireKPMixChannel(mInfo)
    local lChannels = {}
    for id, mData in pairs(mInfo) do
        local lDesc = mData.desc
        for _,sDesc in ipairs(lDesc) do
            if sDesc == "kp_android" or sDesc == "kp_ios" then
                table.insert(lChannels, id)
            end
        end
    end
    return lChannels
end

local function RequireSMMixChannel(mInfo)
    local lChannels = {}
    for id, mData in pairs(mInfo) do
        local lDesc = mData.desc
        for _,sDesc in ipairs(lDesc) do
            if sDesc == "sm_android" or sDesc == "sm_ios" then
                table.insert(lChannels, id)
            end
        end
    end
    return lChannels
end

local function RequirePlatChannel(mInfo)
    local mGroup = {}
    for id, mData in pairs(mInfo) do
        local lDesc = mData.desc
        for _,sDesc in ipairs(lDesc) do
            local l = mGroup[sDesc]
            if not l then
                l = {}
                mGroup[sDesc] = l
            end
            table.insert(l, id)
        end
    end
    mGroup["kp_mix"] = RequireKPMixChannel(mInfo)
    mGroup["sm_mix"] = RequireSMMixChannel(mInfo)
    return mGroup
end

local function FormatStr2Second(sTime)
    local Y = string.sub(sTime, 1, 4)
    local m = string.sub(sTime, 6, 7)
    local d = string.sub(sTime, 9, 10)
    local H = string.sub(sTime, 12, 13)
    local M = string.sub(sTime, 15, 16)
    local S = string.sub(sTime, 18, 19)
    return os.time({year=Y, month=m, day=d, hour=H, min=M, sec=S})
end

local function RequireServerInfo()
    local mRet = {}
    for _,sKey in pairs({"serverinfo", "serverinfo_pro"}) do
        local mData = Require(sKey)
        for id, m in pairs(mData) do
            m["open_time"] = FormatStr2Second(m["open_time"])
            m["start_time"] = FormatStr2Second(m["start_time"])
            mRet[m["type"]] = mRet[m["type"]] or {}
            mRet[m["type"]][id] = m
        end
    end
    return mRet
end

local function RequirePatrol()
    local mRet = {}
    local mPatrol = Require("map/patrol")
    for _,mData in ipairs(mPatrol) do
        local iMap = mData["map_id"]
        if not mRet[iMap] then
            mRet[iMap] = {}
        end
        table.insert(mRet[iMap],{x=mData["x"],y=mData["y"]})
    end
    return mRet
end

local function OutPath(sFile)
    return string.format("%s/%s.lua", sOutPath, sFile)
end


function _AssertPerformSkill(iSK,sDebug)
	local mSkill = M.skill
	assert(mSkill[iSK],string.format("not found performskill %d %s",iSK,sDebug or ""))
end

function _AssertItem(sItem,sDebug)
	local mItem = M.item
	local sid = string.match(sItem,"(%d+)")
	local iItem = tonumber(sid)
	assert(mItem[iItem],string.format("not found item %d %s %s ",iItem,sItem,sDebug or ""))
end

function _AssertMonster(sName,idx)
	local mMonster = M.monster
	assert(mMonster[sName],string.format("not found file monster/%s",sName))
	assert(mMonster[sName],string.format("not found monster/%s %d",sName,idx))
end

function _AssertPartner(idx, sDebug)
    local mPartner = M.partner["partner_info"]
    assert(mPartner[idx], string.format("not found partner: %s ,%s", idx, sDebug))
end

function RequireMap()
    local mRetData = Require("map/map")
    for iMapid,mData in pairs(mRetData) do
        local iFloatX = mData["width"]
        local iFloatY = mData["height"]
        local lScope = mData["server_scope"]
        local iServerX,iServerY = table.unpack(lScope)
        assert(iServerX>=iFloatX,string.format("map daobiao x err:%s",iMapid))
        assert(iServerY>=iFloatY,string.format("map daobiao y err:%s",iMapid))
    end
    return mRetData
end

function RequireTaskNpc()
    local iCnt = 3
    local mRet = {}
    for i = 1,iCnt do
        local sFile = string.format("npc/task_npc_%d",i)
        local m = Require(sFile)
        for id,mData in pairs(m) do
            mRet[id] = mData
        end
    end
    return mRet
end

function RequireTimeLimitResume()
    local m = {}
    m["reward_info"] = Require("huodong/welfare/timelimit_resume")
    m["plan_info"] = Require("huodong/welfare/timelimit_plan")
    return m
end

--daobiao begin

M.example = Require("example")
M.scene = Require("map/scene")


M.perform = RequirePerform()
M.buff = Require("perform/buff")
M.bufflimit = Require("perform/bufflimit")
M.performratio = Require("perform/performratio")
M.skill = RequireSkill()
M.aura = RequireAura()
M.init_skill = Require("skill/init_skill")
M.cultivate_skill = RequireCultivateSkill()
M.buff_effect = RequireBuffEffect()
M.buff_smallgroup = Require("perform/buff_smallgroup")

M.item = RequireItem()


M.map = RequireMap()
M.point = Require("role/point")
M.school = Require("role/school")
M.upgrade = RequireUpGrade()
M.servergrade = Require("role/servergrade")
M.washpoint = Require("role/washpoint")
M.roleprop = Require("role/roleprop")
M.roletype = Require("role/roletype")
M.roleattr = RequireRoleAttr()
M.rolebranch = RequireRoleBranch()
M.roleskin = Require("role/roleskin")
M.goldlimit = Require("role/goldlimit")
M.silverlimit = Require("role/silverlimit")
M.global = Require("global")
M.mail = Require("mail")
M.attrname = Require("role/attrname")
M.school_convert_power = Require("role/convert_power")
M.schoolweapon = RequireSchoolWeanpon()
M.global_control = Require("global_control")
M.question_time = Require("huodong/question/question_time")
M.question_pool = Require("huodong/question/question_pool")
M.score_question_reward = Require("huodong/question/score_question_reward")
M.scene_question = Require("huodong/question/scene_question")
M.question_member = Require("huodong/question/member_limit")
M.scene_question_reward = Require("huodong/question/scene_question_reward")

M.equippos = Require("item/equippos")
M.equip_wave = Require("item/equip_wave")
M.equip_quality = Require("item/equip_quality")
M.gem_level = Require("item/gem_level")
M.fuwen = RequireFuwen()
M.fuwen_wave = Require("item/fuwen_wave")
M.fuwen_quality = RequireFuwenQuality()
M.strength = RequireStrength()
M.newrole_equip = Require("item/newrole_equip")
M.school_equip = Require("item/born_school_equip")
M.second_weapon = Require("item/second_weapon")
M.equip_se = Require("item/equip_se")
M.equip_set = Require("item/equip_set")
M.buffstone = Require("item/stonebuff")

M.global_npc = RequireNpc()
M.dialog_npc = Require("npc/dialog_npc")
M.task_npc = RequireTaskNpc()
M.npcgroup = Require("npc/npcgroup")
-- M.npcshop = RequireNPCShop("npc/npcshop")

M.task = RequireTask()
M.huodong = RequireHuodong()
M.monster = RequireMonster()
M.tollgate = RequireFight()
M.reward = RequireReward()
M.shimenratio = Require("task/shimen/shimenratio")
M.scenemonster = Require("huodong/trapmine/scenemonster")

M.itemgroup = Require("item/itemgroup")
--M.taskitem = Require("task/taskitem")
M.scenegroup = Require("map/scenegroup")
M.scenefly = Require("map/scenefly")
--M.tasktext = Require("task/tasktext")
M.team = {}
M.autoteam = Require("autoteam")
M.team.text  = Require("team/text")
M.chatconfig = Require("chat/chatconfig")
M.chuanyinchat = Require("chat/chuanyin")
M.gonggao = Require("chat/gonggao")
M.chuanwen = Require("chat/chuanwen")
M.schedule = RequireSchedule()
M.compound = Require("item/compound")
M.decompose = Require("item/decompose")
M.equip_compose = RequireEquipCompose()
M.exchange_equip = Require("item/exchange_equip")



M.itemcolor = Require("itemcolor")
M.othercolor = Require("othercolor")
M.partnercolor = Require("partnercolor")
M.state = Require("state")
M.open = Require("open")
M.text = RequireText()
M.partner = RequirePartner()
M.partner_item = RequirePartnerItem()
M.shopinfo = RequireShop()
M.gold2coin = Require("store/gold2coin")

M.housepartner = Require("house/housepartner")
M.furniture = RequireHouseFurniture()
M.furniture_lock = Require("house/furniture_lock")
M.talent_gift = Require("house/talent_gift")
M.housedefines = Require("house/housedefines")
M.houselove = Require("house/houselove")
M.lovestage = Require("house/love_stage")
M.partner_love = RequireHousePartnerLove()
M.partner_train = Require("house/partner_train")
M.partner_path = Require("house/partner_path")
M.house_workdesk = Require("house/workdesk")
M.house_lovebuff = Require("house/love_buff")

M.partner_task = RequireHousePartnerTask()
M.barrage = Require("barrage")
M.task_barrage = RequireTaskBarrage()
M.friend = {}
M.friend.text = Require("friend/text")
M.title = RequireTitle()
M.org = RequireOrg()

M.rank = Require("system/rank/rankinfo")
M.rank_reward = RequireRankReward()
M.rushrank = RequireRushRank()
M.rushconfig = Require("system/rank/rushconfig")
M.arena = RequireArenaGame()
M.randomname = RequireRandomName()
M.virtualname = RequireVirtualName()
M.endless_pve = RequireEndlessPVE()
M.log = RequireLog()
M.playconfig = RequirePlayConfig()
M.invitecode = Require("invite_code")
M.achieve = RequireAchieve()
M.handbook = RequireHandbook()
M.hongbao = RequireHongBao()
M.pay = RequirePay()
M.demichannel = Require("demichannel")
M.goldcoinstore = Require("store/goldcoinstore")
M.allchannel = RequireAllChannel(M.demichannel)
M.platchannel = RequirePlatChannel(M.demichannel)
M.first_charge = Require("huodong/welfare/first_charge")
M.fulicharge = Require("huodong/welfare/total_recharge")
M.timelimit_resume = RequireTimeLimitResume()
M.consume_point = Require("huodong/welfare/consume_point")
M.consume_plan = Require("huodong/welfare/consume_plan")
M.welfare_control = Require("huodong/welfare/welfare_control")
M.welfare_limit = Require("huodong/welfare/welfare_limit")
M.rechagescore = RequireRechargeScore()
M.battle_command = Require("fight/battle_command")
M.gonggao_priority = Require("gonggao_priority")
M.serverinfo = RequireServerInfo()
M.servergroup = Require("servergroup")
M.patrol = RequirePatrol()
M.onfight = Require("role/onfight")
M.gameshare = Require("gameshare")
M.luck_draw = RequireLuckDraw()
M.yybaogift = Require("yybaogift")
M.qqgift = Require("qqgift")
M.gamepush = Require("system/gamepush/gamepush")
M.gain_goldcoin = Require("system/updata/gain_goldcoin")
M.cost_goldcoin = Require("system/updata/cost_goldcoin")
M.open_limit = Require("huodong/limitopen/limitopen")
M.welfare_rank = RequireWelfareRushRank()
--daobiao end

local s = dumpapi(M)
local f = io.open(OutPath("data"), "wb")
f:write(s)
f:close()
