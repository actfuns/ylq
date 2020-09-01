-- ./excel/log/orgwar.xlsx
return {

    ["divide"] = {
        desc = "对战信息",
        log_format = {["orgid1"] = {["id"] = "orgid1", ["desc"] = "蓝方"}, ["orgid2"] = {["id"] = "orgid2", ["desc"] = "红方"}},
        subtype = "divide",
    },

    ["enterwar"] = {
        desc = "进入战斗",
        log_format = {["mem1"] = {["id"] = "mem1", ["desc"] = "攻方"}, ["mem2"] = {["id"] = "mem2", ["desc"] = "守方"}},
        subtype = "enterwar",
    },

    ["warcnt"] = {
        desc = "战斗次数",
        log_format = {["cnt"] = {["id"] = "cnt", ["desc"] = "战斗次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家pid"}},
        subtype = "warcnt",
    },

    ["judge"] = {
        desc = "胜负记录",
        log_format = {["failid"] = {["id"] = "failid", ["desc"] = "战败ID"}, ["winid"] = {["id"] = "winid", ["desc"] = "胜利ID"}},
        subtype = "judge",
    },

}
