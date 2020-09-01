-- ./excel/log/rewardback.xlsx
return {

    ["reward"] = {
        desc = "奖励找回",
        log_format = {["cnt"] = {["id"] = "cnt", ["desc"] = "找回次数"}, ["cost"] = {["id"] = "cost", ["desc"] = "消耗水晶"}, ["name"] = {["id"] = "name", ["desc"] = "玩法类型"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "reward",
    },

    ["build"] = {
        desc = "奖励生成",
        log_format = {["back"] = {["id"] = "back", ["desc"] = "生成奖励"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "build",
    },

}
