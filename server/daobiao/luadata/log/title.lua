-- ./excel/log/title.xlsx
return {

    ["add"] = {
        desc = "增加",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["tid"] = {["id"] = "tid", ["desc"] = "称谓id"}},
        subtype = "add",
    },

    ["rm"] = {
        desc = "删除",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["tid"] = {["id"] = "tid", ["desc"] = "称谓id"}},
        subtype = "rm",
    },

}
