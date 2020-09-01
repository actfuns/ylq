-- ./excel/log/npcfight.xlsx
return {

    ["warstart"] = {
        desc = "开启战斗",
        log_format = {["npcid"] = {["id"] = "npcid", ["desc"] = "导表id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["remain"] = {["id"] = "remain", ["desc"] = "剩余次数"}, ["tollgate"] = {["id"] = "tollgate", ["desc"] = "关卡id"}},
        subtype = "warstart",
    },

    ["warend"] = {
        desc = "战斗结束",
        log_format = {["npcid"] = {["id"] = "npcid", ["desc"] = "导表id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["remain"] = {["id"] = "remain", ["desc"] = "剩余次数"}, ["result"] = {["id"] = "result", ["desc"] = "结果(1胜利)"}, ["tollgate"] = {["id"] = "tollgate", ["desc"] = "关卡id"}},
        subtype = "warend",
    },

    ["reward"] = {
        desc = "挑战奖励",
        log_format = {["npcid"] = {["id"] = "npcid", ["desc"] = "导表id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励id"}},
        subtype = "reward",
    },

}
