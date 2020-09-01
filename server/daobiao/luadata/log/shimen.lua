-- ./excel/log/shimen.xlsx
return {

    ["receivetask"] = {
        desc = "接受委托",
        log_format = {["cur_time"] = {["id"] = "cur_time", ["desc"] = "当前环数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "receivetask",
    },

    ["finishtask"] = {
        desc = "交付委托",
        log_format = {["cur_time"] = {["id"] = "cur_time", ["desc"] = "当前环数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "finishtask",
    },

}
