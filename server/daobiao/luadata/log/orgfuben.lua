-- ./excel/log/orgfuben.xlsx
return {

    ["join_war"] = {
        desc = "公会推图-开始战斗",
        log_format = {["boss"] = {["id"] = "boss", ["desc"] = "bossID"}, ["boss_hp"] = {["id"] = "boss_hp", ["desc"] = "BOSS当前血量"}, ["left"] = {["id"] = "left", ["desc"] = "剩余次数"}, ["org"] = {["id"] = "org", ["desc"] = "公会ID"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "join_war",
    },

    ["reset"] = {
        desc = "公会推图-重置",
        log_format = {["boss_info"] = {["id"] = "boss_info", ["desc"] = "重置前的进度"}, ["boss_reset"] = {["id"] = "boss_reset", ["desc"] = "boss重置后信息"}, ["cost"] = {["id"] = "cost", ["desc"] = "花费"}, ["org"] = {["id"] = "org", ["desc"] = "公会ID"}, ["pid"] = {["id"] = "pid", ["desc"] = "重置玩家"}, ["post"] = {["id"] = "post", ["desc"] = "职位"}, ["use"] = {["id"] = "use", ["desc"] = "已使用次数"}},
        subtype = "reset",
    },

    ["war_end"] = {
        desc = "公会推图-战斗结束",
        log_format = {["boss"] = {["id"] = "boss", ["desc"] = "BOSS的ID"}, ["hit"] = {["id"] = "hit", ["desc"] = "战斗总伤害"}, ["left"] = {["id"] = "left", ["desc"] = "剩余次数"}, ["org"] = {["id"] = "org", ["desc"] = "公会ID"}, ["partlist"] = {["id"] = "partlist", ["desc"] = "参战伙伴"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "war_end",
    },

    ["boss_die"] = {
        desc = "公会推图-BOSS击杀",
        log_format = {["boss"] = {["id"] = "boss", ["desc"] = "bossID"}, ["org"] = {["id"] = "org", ["desc"] = "公会ID"}, ["reward_list"] = {["id"] = "reward_list", ["desc"] = "奖励人员"}},
        subtype = "boss_die",
    },

    ["rubbish_org"] = {
        desc = "公会推图-清除公会信息",
        log_format = {["org"] = {["id"] = "org", ["desc"] = "公会ID"}},
        subtype = "rubbish_org",
    },

}
