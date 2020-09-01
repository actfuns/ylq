-- ./excel/huodong/convoy/dialog.xlsx
return {

    [100] = {
        content = "帝都宅急便招人啦，酬劳好高哦。不管枪林弹雨还是高山深海，我们一定能送达。\n(剩余次数:$lefttime次)",
        dialog_id = 100,
        last_action = {{["content"] = "乐意接受", ["event"] = "doit"}, {["content"] = "考虑一下"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [101] = {
        content = "今天委托次数已满，请于明天再来领取任务",
        dialog_id = 101,
        last_action = {},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [102] = {
        content = "你完成了此次委托，是否继续过来接受委托？\n(剩余次数:$lefttime次)",
        dialog_id = 102,
        last_action = {{["content"] = "前往接受", ["event"] = "continue"}, {["content"] = "考虑一下"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

}
