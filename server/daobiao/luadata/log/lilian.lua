-- ./excel/log/lilian.xlsx
return {

    ["enter_fight"] = {
        desc = "开始历练",
        log_format = {["fightid"] = {["id"] = "fightid", ["desc"] = "战斗ID"}, ["mem_grade"] = {["id"] = "mem_grade", ["desc"] = "平均等级"}, ["monster_grade"] = {["id"] = "monster_grade", ["desc"] = "怪物等级"}, ["teammem"] = {["id"] = "teammem", ["desc"] = "队伍成员"}},
        subtype = "enter_fight",
    },

    ["fight_end"] = {
        desc = "战斗结束",
        log_format = {["fightid"] = {["id"] = "fightid", ["desc"] = "战斗ID"}, ["mem_grade"] = {["id"] = "mem_grade", ["desc"] = "平均等级"}, ["monster_grade"] = {["id"] = "monster_grade", ["desc"] = "怪物等级"}, ["result"] = {["id"] = "result", ["desc"] = "战斗结果"}, ["teammem"] = {["id"] = "teammem", ["desc"] = "队伍成员"}},
        subtype = "fight_end",
    },

    ["times_change"] = {
        desc = "次数变化",
        log_format = {["newtimes"] = {["id"] = "newtimes", ["desc"] = "变化后次数"}, ["oldtimes"] = {["id"] = "oldtimes", ["desc"] = "原有次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "times_change",
    },

}
