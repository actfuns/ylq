-- ./excel/log/convoy.xlsx
return {

    ["reset"] = {
        desc = "更新护送信息",
        log_format = {["free_time"] = {["id"] = "free_time", ["desc"] = "剩余免费次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["pool_info"] = {["id"] = "pool_info", ["desc"] = "护送池信息"}, ["refresh_cost"] = {["id"] = "refresh_cost", ["desc"] = "下次刷新费用"}, ["refresh_time"] = {["id"] = "refresh_time", ["desc"] = "刷新次数"}, ["status"] = {["id"] = "status", ["desc"] = "护送状态"}},
        subtype = "reset",
    },

    ["refresh"] = {
        desc = "刷新目标",
        log_format = {["cost"] = {["id"] = "cost", ["desc"] = "刷新费用"}, ["newlevel"] = {["id"] = "newlevel", ["desc"] = "新档次"}, ["oldlevel"] = {["id"] = "oldlevel", ["desc"] = "旧档次"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["refresh_time"] = {["id"] = "refresh_time", ["desc"] = "刷新次数"}},
        subtype = "refresh",
    },

    ["giveup"] = {
        desc = "放弃护送",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "giveup",
    },

    ["start"] = {
        desc = "开始护送",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["times"] = {["id"] = "times", ["desc"] = "护送次数"}},
        subtype = "start",
    },

    ["win"] = {
        desc = "护送成功",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["rewardid"] = {["id"] = "rewardid", ["desc"] = "奖励ID"}},
        subtype = "win",
    },

    ["failed"] = {
        desc = "护送失败",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "failed",
    },

}
