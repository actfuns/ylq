-- ./excel/log/fieldboss.xlsx
return {

    ["foece_pk"] = {
        desc = "玩家pk",
        log_format = {["bossid"] = {["id"] = "bossid", ["desc"] = "bossid"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["target"] = {["id"] = "target", ["desc"] = "目标玩家ID"}},
        subtype = "foece_pk",
    },

    ["pk_result"] = {
        desc = "pk结果",
        log_format = {["bossid"] = {["id"] = "bossid", ["desc"] = "bossid"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["target"] = {["id"] = "target", ["desc"] = "目标玩家ID"}, ["winner"] = {["id"] = "winner", ["desc"] = "获胜方"}},
        subtype = "pk_result",
    },

    ["boss_fight"] = {
        desc = "boss战",
        log_format = {["bossid"] = {["id"] = "bossid", ["desc"] = "bossid"}, ["damage"] = {["id"] = "damage", ["desc"] = "伤害值"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "boss_fight",
    },

    ["boss_dead"] = {
        desc = "boss死亡",
        log_format = {["bossid"] = {["id"] = "bossid", ["desc"] = "bossid"}, ["pid"] = {["id"] = "pid", ["desc"] = "击杀者ID"}},
        subtype = "boss_dead",
    },

    ["boss_reborn"] = {
        desc = "boss出现",
        log_format = {["bossid"] = {["id"] = "bossid", ["desc"] = "bossid"}},
        subtype = "boss_reborn",
    },

    ["reward"] = {
        desc = "获得奖励",
        log_format = {["bossid"] = {["id"] = "bossid", ["desc"] = "bossid"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["reward_type"] = {["id"] = "reward_type", ["desc"] = "奖励类型"}, ["rewardid"] = {["id"] = "rewardid", ["desc"] = "奖励id"}},
        subtype = "reward",
    },

}
