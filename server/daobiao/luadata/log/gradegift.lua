-- ./excel/log/gradegift.xlsx
return {

    ["buy_gift"] = {
        desc = "购买礼包",
        log_format = {["buy"] = {["id"] = "buy", ["desc"] = "购买次数"}, ["gift_grade"] = {["id"] = "gift_grade", ["desc"] = "礼包等级"}, ["item"] = {["id"] = "item", ["desc"] = "奖励信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "buy_gift",
    },

    ["free_gift"] = {
        desc = "领取免费",
        log_format = {["free"] = {["id"] = "free", ["desc"] = "领取状态"}, ["gift_grade"] = {["id"] = "gift_grade", ["desc"] = "礼包等级"}, ["item"] = {["id"] = "item", ["desc"] = "奖励信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "free_gift",
    },

    ["gift_status"] = {
        desc = "礼包状态",
        log_format = {["gift_grade"] = {["id"] = "gift_grade", ["desc"] = "礼包等级"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["status"] = {["id"] = "status", ["desc"] = "礼包状态"}},
        subtype = "gift_status",
    },

}
