-- ./excel/log/achieve.xlsx
return {

    ["ach_change"] = {
        desc = "成就进度",
        log_format = {["aid"] = {["id"] = "aid", ["desc"] = "成就ID"}, ["degree"] = {["id"] = "degree", ["desc"] = "当前进度"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "ach_change",
    },

    ["ach_done"] = {
        desc = "成就达成",
        log_format = {["aid"] = {["id"] = "aid", ["desc"] = "成就ID"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "ach_done",
    },

    ["ach_reward"] = {
        desc = "成就奖励",
        log_format = {["aid"] = {["id"] = "aid", ["desc"] = "成就ID"}, ["item"] = {["id"] = "item", ["desc"] = "物品列表"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "ach_reward",
    },

    ["point_reward"] = {
        desc = "成就点奖励",
        log_format = {["id"] = {["id"] = "id", ["desc"] = "成就点ID"}, ["item"] = {["id"] = "item", ["desc"] = "物品列表"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "point_reward",
    },

    ["sevday_change"] = {
        desc = "七日目标进度",
        log_format = {["aid"] = {["id"] = "aid", ["desc"] = "成就ID"}, ["degree"] = {["id"] = "degree", ["desc"] = "当前进度"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "sevday_change",
    },

    ["sevday_done"] = {
        desc = "七日目标达成",
        log_format = {["aid"] = {["id"] = "aid", ["desc"] = "成就ID"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "sevday_done",
    },

    ["sev_reward"] = {
        desc = "七日目标奖励",
        log_format = {["aid"] = {["id"] = "aid", ["desc"] = "成就ID"}, ["item"] = {["id"] = "item", ["desc"] = "物品列表"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "sev_reward",
    },

    ["sev_point_reward"] = {
        desc = "七日目标进度奖励",
        log_format = {["id"] = {["id"] = "id", ["desc"] = "成就点ID"}, ["item"] = {["id"] = "item", ["desc"] = "物品列表"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["title"] = {["id"] = "title", ["desc"] = "称号"}},
        subtype = "sev_point_reward",
    },

    ["sev_gift_reward"] = {
        desc = "七日目标礼包",
        log_format = {["day"] = {["id"] = "day", ["desc"] = "礼包天数"}, ["item"] = {["id"] = "item", ["desc"] = "物品列表"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "sev_gift_reward",
    },

    ["sev_end_mail"] = {
        desc = "七日结束物品邮件",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["sevinfo"] = {["id"] = "sevinfo", ["desc"] = "未领取信息"}},
        subtype = "sev_end_mail",
    },

}
