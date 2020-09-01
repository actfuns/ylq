-- ./excel/log/equalarena.xlsx
return {

    ["start_pvp"] = {
        desc = "进入PVP战斗",
        log_format = {["count1"] = {["id"] = "count1", ["desc"] = "次数"}, ["count2"] = {["id"] = "count2", ["desc"] = "次数"}, ["name1"] = {["id"] = "name1", ["desc"] = "玩家名字"}, ["name2"] = {["id"] = "name2", ["desc"] = "玩家名字"}, ["pid1"] = {["id"] = "pid1", ["desc"] = "玩家ID"}, ["pid2"] = {["id"] = "pid2", ["desc"] = "玩家ID"}, ["point1"] = {["id"] = "point1", ["desc"] = "比武积分"}, ["point2"] = {["id"] = "point2", ["desc"] = "比武积分"}},
        subtype = "start_pvp",
    },

    ["start_robot"] = {
        desc = "进入机器人战斗",
        log_format = {["count"] = {["id"] = "count", ["desc"] = "参战次数"}, ["name"] = {["id"] = "name", ["desc"] = "名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["point"] = {["id"] = "point", ["desc"] = "比武积分"}, ["robot_name"] = {["id"] = "robot_name", ["desc"] = "机器人名字"}, ["robot_point"] = {["id"] = "robot_point", ["desc"] = "机器人积分"}},
        subtype = "start_robot",
    },

    ["week_reward"] = {
        desc = "每周竞技奖励",
        log_format = {["lastweek"] = {["id"] = "lastweek", ["desc"] = "最后参战周"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["point"] = {["id"] = "point", ["desc"] = "积分"}, ["stage"] = {["id"] = "stage", ["desc"] = "段位"}, ["week"] = {["id"] = "week", ["desc"] = "奖励周"}},
        subtype = "week_reward",
    },

    ["week_rank"] = {
        desc = "每周排行榜奖励 ",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["rank"] = {["id"] = "rank", ["desc"] = "排名"}, ["score"] = {["id"] = "score", ["desc"] = "积分"}},
        subtype = "week_rank",
    },

    ["end_arena"] = {
        desc = "战斗结算信息",
        log_format = {["addpoint1"] = {["id"] = "addpoint1", ["desc"] = "积分变化"}, ["addpoint2"] = {["id"] = "addpoint2", ["desc"] = "积分变化"}, ["name1"] = {["id"] = "name1", ["desc"] = "玩家名字"}, ["name2"] = {["id"] = "name2", ["desc"] = "玩家名字"}, ["pid1"] = {["id"] = "pid1", ["desc"] = "玩家ID"}, ["pid2"] = {["id"] = "pid2", ["desc"] = "玩家ID(=0为机器人)"}, ["point1"] = {["id"] = "point1", ["desc"] = "结束后积分"}, ["point2"] = {["id"] = "point2", ["desc"] = "结束后积分"}, ["win"] = {["id"] = "win", ["desc"] = "获胜者ID"}},
        subtype = "end_arena",
    },

}
