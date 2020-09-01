-- ./excel/log/fuli.xlsx
return {

    ["chargereward"] = {
        desc = "累计充值",
        log_format = {["iteminfo"] = {["id"] = "iteminfo", ["desc"] = "物品信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["title"] = {["id"] = "title", ["desc"] = "称谓"}},
        subtype = "chargereward",
    },

    ["firstcharge"] = {
        desc = "首充奖励",
        log_format = {["iteminfo"] = {["id"] = "iteminfo", ["desc"] = "物品信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "firstcharge",
    },

    ["addcspoint"] = {
        desc = "增加消费积分",
        log_format = {["add"] = {["id"] = "add", ["desc"] = "增加值"}, ["now"] = {["id"] = "now", ["desc"] = "当前积分"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "addcspoint",
    },

    ["resumecspoint"] = {
        desc = "消费积分兑换",
        log_format = {["id"] = {["id"] = "id", ["desc"] = "商品id"}, ["now"] = {["id"] = "now", ["desc"] = "当前积分"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["sub"] = {["id"] = "sub", ["desc"] = "减少值"}},
        subtype = "resumecspoint",
    },

    ["addluckdraw"] = {
        desc = "增加幸运转盘次数",
        log_format = {["add"] = {["id"] = "add", ["desc"] = "增加值"}, ["now"] = {["id"] = "now", ["desc"] = "当前次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "addluckdraw",
    },

    ["luckreward"] = {
        desc = "转盘结果",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "物品数量"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["sid"] = {["id"] = "sid", ["desc"] = "物品编号"}},
        subtype = "luckreward",
    },

}
