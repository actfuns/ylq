-- ./excel/log/timelimitresume.xlsx
return {

    ["addscore"] = {
        desc = "获得积分",
        log_format = {["add_score"] = {["id"] = "add_score", ["desc"] = "新增积分"}, ["new_score"] = {["id"] = "new_score", ["desc"] = "获得后积分"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "当前方案"}, ["time"] = {["id"] = "time", ["desc"] = "获得时间"}},
        subtype = "addscore",
    },

    ["resumescore"] = {
        desc = "消耗积分",
        log_format = {["itemid"] = {["id"] = "itemid", ["desc"] = "道具id"}, ["new_score"] = {["id"] = "new_score", ["desc"] = "消费后积分"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "当前方案"}, ["resume_score"] = {["id"] = "resume_score", ["desc"] = "消费积分"}, ["resume_times"] = {["id"] = "resume_times", ["desc"] = "兑换次数"}, ["time"] = {["id"] = "time", ["desc"] = "获得时间"}},
        subtype = "resumescore",
    },

}
