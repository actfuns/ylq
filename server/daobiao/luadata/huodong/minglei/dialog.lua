-- ./excel/huodong/minglei/dialog.xlsx
return {

    [100] = {
        content = "茶会？茶会！茶会！我擦，又来了，我闪！（受邀者准备开溜了，2人以上才可以拦住他唷。）\n已进行次数：{done_time}/{totaltime}（今日还可购买{left_buytime}次）",
        dialog_id = 100,
        last_action = {{["content"] = "战斗", ["event"] = "MLF"}, {["content"] = "发起组队", ["event"] = "CT"}, {["content"] = "购买次数", ["event"] = "BUY"}, {["content"] = "放弃"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [200] = {
        content = "嗯，你来晚了一步，他已经和别人打起来了，请稍后再来。",
        dialog_id = 200,
        last_action = {},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [300] = {
        content = "你等级不足20级，小孩子就不要去了哈。",
        dialog_id = 300,
        last_action = {},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [400] = {
        content = "是否去与{monstername}试一试?\n可进行次数：{left_fighttime}/{totaltime}（今日还可购买{left_buytime}次）",
        dialog_id = 400,
        last_action = {{["content"] = "发起组队", ["event"] = "CT"}, {["content"] = "进入战斗", ["event"] = "ENTER"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

}
