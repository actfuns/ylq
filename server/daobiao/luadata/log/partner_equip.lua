-- ./excel/log/partner.xlsx
return {

    ["add_exp"] = {
        desc = "符文培养",
        log_format = {["exp_add"] = {["id"] = "exp_add", ["desc"] = "增加经验"}, ["exp_now"] = {["id"] = "exp_now", ["desc"] = "当前经验"}, ["exp_old"] = {["id"] = "exp_old", ["desc"] = "原经验"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["sid"] = {["id"] = "sid", ["desc"] = "道具sid"}, ["trace"] = {["id"] = "trace", ["desc"] = "跟踪id"}},
        subtype = "add_exp",
    },

    ["error"] = {
        desc = "错误log",
        log_format = {["parid"] = {["id"] = "parid", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["sid"] = {["id"] = "sid", ["desc"] = "道具sid"}, ["trace"] = {["id"] = "trace", ["desc"] = "跟踪id"}},
        subtype = "error",
    },

}
