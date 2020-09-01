-- ./excel/log/yjfuben.xlsx
return {

    ["monster"] = {
        desc = "怪物刷新",
        log_format = {["info"] = {["id"] = "info", ["desc"] = "怪物信息"}},
        subtype = "monster",
    },

    ["entergame"] = {
        desc = "进入副本",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "entergame",
    },

    ["addpoint"] = {
        desc = "副本积分",
        log_format = {["add"] = {["id"] = "add", ["desc"] = "增加积分"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["point"] = {["id"] = "point", ["desc"] = "当前积分"}},
        subtype = "addpoint",
    },

    ["fubencnt"] = {
        desc = "副本次数",
        log_format = {["cnt"] = {["id"] = "cnt", ["desc"] = "次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "fubencnt",
    },

    ["cntlimit"] = {
        desc = "副本次数限制",
        log_format = {["limit"] = {["id"] = "limit", ["desc"] = "限制次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "cntlimit",
    },

    ["beatboss"] = {
        desc = "击败怪物信息",
        log_format = {["info"] = {["id"] = "info", ["desc"] = "怪物信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "beatboss",
    },

}
