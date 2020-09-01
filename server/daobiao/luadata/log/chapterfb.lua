-- ./excel/log/chapterfb.xlsx
return {

    ["chellange"] = {
        desc = "挑战副本",
        log_format = {["chapter"] = {["id"] = "chapter", ["desc"] = "章节"}, ["level"] = {["id"] = "level", ["desc"] = "关卡"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["type"] = {["id"] = "type", ["desc"] = "难度"}},
        subtype = "chellange",
    },

    ["win"] = {
        desc = "副本获胜",
        log_format = {["chapter"] = {["id"] = "chapter", ["desc"] = "章节"}, ["level"] = {["id"] = "level", ["desc"] = "关卡"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}, ["star"] = {["id"] = "star", ["desc"] = "星级"}, ["type"] = {["id"] = "type", ["desc"] = "难度"}},
        subtype = "win",
    },

    ["failed"] = {
        desc = "副本失败",
        log_format = {["chapter"] = {["id"] = "chapter", ["desc"] = "章节"}, ["level"] = {["id"] = "level", ["desc"] = "关卡"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["type"] = {["id"] = "type", ["desc"] = "难度"}},
        subtype = "failed",
    },

    ["sweep"] = {
        desc = "扫荡副本",
        log_format = {["chapter"] = {["id"] = "chapter", ["desc"] = "章节"}, ["level"] = {["id"] = "level", ["desc"] = "关卡"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}, ["times"] = {["id"] = "times", ["desc"] = "扫荡次数"}, ["type"] = {["id"] = "type", ["desc"] = "难度"}},
        subtype = "sweep",
    },

    ["extra_reward"] = {
        desc = "获得关卡额外奖励",
        log_format = {["chapter"] = {["id"] = "chapter", ["desc"] = "章节"}, ["level"] = {["id"] = "level", ["desc"] = "关卡"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}, ["type"] = {["id"] = "type", ["desc"] = "难度"}},
        subtype = "extra_reward",
    },

    ["star_reward"] = {
        desc = "获得星级奖励",
        log_format = {["chapter"] = {["id"] = "chapter", ["desc"] = "章节"}, ["index"] = {["id"] = "index", ["desc"] = "宝箱位置"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}, ["type"] = {["id"] = "type", ["desc"] = "难度"}},
        subtype = "star_reward",
    },

}
