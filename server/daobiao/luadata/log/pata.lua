-- ./excel/log/pata.xlsx
return {

    ["warwin"] = {
        desc = "战斗胜利",
        log_format = {["curlv"] = {["id"] = "curlv", ["desc"] = "层数"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["power"] = {["id"] = "power", ["desc"] = "玩家战斗力"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}},
        subtype = "warwin",
    },

    ["swp"] = {
        desc = "扫荡",
        log_format = {["beginlv"] = {["id"] = "beginlv", ["desc"] = "开始层数"}, ["endlv"] = {["id"] = "endlv", ["desc"] = "结束层数"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["power"] = {["id"] = "power", ["desc"] = "玩家战斗力"}},
        subtype = "swp",
    },

    ["reset"] = {
        desc = "重置",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "reset",
    },

    ["fristrw"] = {
        desc = "领取首通奖励",
        log_format = {["curlv"] = {["id"] = "curlv", ["desc"] = "层数"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}},
        subtype = "fristrw",
    },

    ["getrw"] = {
        desc = "地牢领奖",
        log_format = {["curlv"] = {["id"] = "curlv", ["desc"] = "层数"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}},
        subtype = "getrw",
    },

    ["friend"] = {
        desc = "好友邀请次数",
        log_format = {["cnt"] = {["id"] = "cnt", ["desc"] = "邀请次数"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "friend",
    },

}
