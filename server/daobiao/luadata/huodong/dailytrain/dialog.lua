-- ./excel/huodong/dailytrain/dialog.xlsx
return {

    [1] = {
        content = [=[每天可无限修行，并在0：00获得60次高倍奖励（最多累积420次，当前剩余$lefttime次），修行可获得海量主角/伙伴经验和金币，快组队开跑吧。
3人以上立刻开跑，组满4人队长获得经验金币加成]=],
        dialog_id = 100,
        finish_event = "",
        last_action = {{["content"] = "开始修行", ["event"] = "START"}, {["content"] = "便捷组队", ["event"] = "CREATETEAM"}, {["content"] = "打酱油", ["event"] = "GIVEUP"}},
        next = "0",
        pre_id_list = "0",
        status = 1,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [2] = {
        content = "你不在队伍中，不考虑建个队或者混个队吗？担当队长组满4人有经验金币加成喔",
        dialog_id = 200,
        finish_event = "",
        last_action = {{["content"] = "创建队伍", ["event"] = "CreateDailyTrainTeam"}, {["content"] = "加入队伍", ["event"] = "JoinDailyTrainTeam"}, {["content"] = "考虑一下", ["event"] = "GIVEUP"}},
        next = "0",
        pre_id_list = "0",
        status = 1,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [3] = {
        content = "每日修行$level级开启",
        dialog_id = 300,
        finish_event = "",
        last_action = {},
        next = "0",
        pre_id_list = "0",
        status = 1,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

}
