-- ./excel/log/msattack.xlsx
return {

    ["reward"] = {
        desc = "战斗奖励",
        log_format = {["item"] = {["id"] = "item", ["desc"] = "物品信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "reward",
    },

    ["addpoint"] = {
        desc = "积分增加",
        log_format = {["add"] = {["id"] = "add", ["desc"] = "增加部分"}, ["old"] = {["id"] = "old", ["desc"] = "增加前积分"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["point"] = {["id"] = "point", ["desc"] = "当前积分"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "addpoint",
    },

    ["refresh"] = {
        desc = "刷怪",
        log_format = {["large"] = {["id"] = "large", ["desc"] = "大怪数量"}, ["middle"] = {["id"] = "middle", ["desc"] = "中怪数量"}, ["small"] = {["id"] = "small", ["desc"] = "小怪数量"}},
        subtype = "refresh",
    },

    ["defend"] = {
        desc = "城池防御值变动",
        log_format = {["new"] = {["id"] = "new", ["desc"] = "减少后"}, ["old"] = {["id"] = "old", ["desc"] = "减少前"}, ["sub"] = {["id"] = "sub", ["desc"] = "减少值"}},
        subtype = "defend",
    },

}
