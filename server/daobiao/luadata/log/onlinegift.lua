-- ./excel/log/onlinegift.xlsx
return {

    ["reset"] = {
        desc = "重置在线时间",
        log_format = {["lastrecordtime"] = {["id"] = "lastrecordtime", ["desc"] = "最后记录时间"}, ["onlinetime"] = {["id"] = "onlinetime", ["desc"] = "在线时长"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["status"] = {["id"] = "status", ["desc"] = "领取状态"}},
        subtype = "reset",
    },

    ["reward"] = {
        desc = "领取奖励",
        log_format = {["lastrecordtime"] = {["id"] = "lastrecordtime", ["desc"] = "最后记录时间"}, ["onlinetime"] = {["id"] = "onlinetime", ["desc"] = "在线时长"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}, ["status"] = {["id"] = "status", ["desc"] = "领取状态"}},
        subtype = "reward",
    },

}
