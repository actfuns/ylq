-- ./excel/huodong/worldboss/dialog.xlsx
return {

    [100] = {
        content = "你要进入协同比武场景吗？",
        dialog_id = 100,
        last_action = {{["content"] = "干翻你"}, {["content"] = "再考虑一下！"}, {["content"] = "送我离开"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [101] = {
        content = "你要离开协同比武场景吗？",
        dialog_id = 101,
        last_action = {{["content"] = "离开比武场景", ["event"] = "doit"}, {["content"] = "再考虑一下！"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

}
