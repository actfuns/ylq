-- ./excel/log/worldboss.xlsx
return {

    ["game_start"] = {
        desc = "活动开始",
        log_format = {["exp"] = {["id"] = "exp", ["desc"] = "经验"}, ["grade"] = {["id"] = "grade", ["desc"] = "boss等级"}, ["hp"] = {["id"] = "hp", ["desc"] = "血气"}, ["playcnt"] = {["id"] = "playcnt", ["desc"] = "人数"}, ["type"] = {["id"] = "type", ["desc"] = "boss类型"}},
        subtype = "game_start",
    },

    ["game_over"] = {
        desc = "活动结束",
        log_format = {["kill"] = {["id"] = "kill", ["desc"] = "是否击杀"}, ["playcnt"] = {["id"] = "playcnt", ["desc"] = "本次参与人数"}},
        subtype = "game_over",
    },

    ["boss_dead"] = {
        desc = "击杀",
        log_format = {["exp"] = {["id"] = "exp", ["desc"] = "经验"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["killer"] = {["id"] = "killer", ["desc"] = "击杀者"}, ["killername"] = {["id"] = "killername", ["desc"] = "名字"}},
        subtype = "boss_dead",
    },

    ["start_war"] = {
        desc = "进入战斗",
        log_format = {["boss_hp"] = {["id"] = "boss_hp", ["desc"] = "boss剩余HP"}, ["name"] = {["id"] = "name", ["desc"] = "名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["play"] = {["id"] = "play", ["desc"] = "参加次数"}},
        subtype = "start_war",
    },

    ["end_war"] = {
        desc = "战斗结束",
        log_format = {["boss_hp"] = {["id"] = "boss_hp", ["desc"] = "boss剩余血量"}, ["hit"] = {["id"] = "hit", ["desc"] = "伤害"}, ["name"] = {["id"] = "name", ["desc"] = "名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["sumhit"] = {["id"] = "sumhit", ["desc"] = "总伤害"}, ["war_partner"] = {["id"] = "war_partner", ["desc"] = "参战伙伴格式"}, ["win"] = {["id"] = "win", ["desc"] = "结果"}},
        subtype = "end_war",
    },

    ["reward_end"] = {
        desc = "结束奖励 ",
        log_format = {["hit"] = {["id"] = "hit", ["desc"] = "伤害"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["rank"] = {["id"] = "rank", ["desc"] = "排名（0为>500的排名）"}},
        subtype = "reward_end",
    },

    ["reward_kill"] = {
        desc = "击杀奖励 ",
        log_format = {["name"] = {["id"] = "name", ["desc"] = "名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "reward_kill",
    },

}
