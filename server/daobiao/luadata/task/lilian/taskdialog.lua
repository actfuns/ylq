-- ./excel/task/lilian/taskdialog.xlsx
return {

    [1] = {
        content = "1:每天0:00获得20次修行机会，最多储存50次；\n2:获得大量主角经验和呆萌鲜肉包；\n你现在还有{liliantime}次，点击开始一键开车",
        dialog_id = 500,
        finish_event = "",
        last_action = {{["content"] = "每日修行", ["event"] = "LILIAN"}},
        next = "0",
        pre_id_list = "0",
        status = 1,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [2] = {
        content = "兄弟们，有人来搞事，给他点颜色look look",
        dialog_id = 501,
        finish_event = "",
        last_action = {{["content"] = "放马过来", ["event"] = "LLFIGHT"}, {["content"] = "身体不适，来日再战"}},
        next = "0",
        pre_id_list = "0",
        status = 1,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

}
