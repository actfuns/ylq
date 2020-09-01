-- ./excel/log/teampvp.xlsx
return {

    ["start_pvp"] = {
        desc = "进入PVP战斗",
        log_format = {["info1"] = {["id"] = "info1", ["desc"] = "玩家信息score=积分name=名字combo=连胜次数win：胜利次数fail=失败次数count=参与次数"}, ["info2"] = {["id"] = "info2", ["desc"] = "玩家信息"}, ["info3"] = {["id"] = "info3", ["desc"] = "玩家信息"}, ["info4"] = {["id"] = "info4", ["desc"] = "玩家信息"}, ["pid1"] = {["id"] = "pid1", ["desc"] = "玩家ID"}, ["pid2"] = {["id"] = "pid2", ["desc"] = "玩家ID"}, ["pid3"] = {["id"] = "pid3", ["desc"] = "玩家ID"}, ["pid4"] = {["id"] = "pid4", ["desc"] = "玩家ID"}},
        subtype = "start_pvp",
    },

    ["end_pvp"] = {
        desc = "战斗结算",
        log_format = {["add_score"] = {["id"] = "add_score", ["desc"] = "增加积分"}, ["cur_score"] = {["id"] = "cur_score", ["desc"] = "当前积分"}, ["medal"] = {["id"] = "medal", ["desc"] = "勋章"}, ["name"] = {["id"] = "name", ["desc"] = "名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["win"] = {["id"] = "win", ["desc"] = "1：胜利0:失败2：逃跑"}},
        subtype = "end_pvp",
    },

    ["reward_rank"] = {
        desc = "前50名排行奖励",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["rank"] = {["id"] = "rank", ["desc"] = "排名（999位安慰奖）"}, ["score"] = {["id"] = "score", ["desc"] = "积分"}},
        subtype = "reward_rank",
    },

}
