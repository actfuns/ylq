-- ./excel/log/one_RMB_gift.xlsx
return {

    ["buy"] = {
        desc = "购买礼包",
        log_format = {["done"] = {["id"] = "done", ["desc"] = "购买信息"}, ["item"] = {["id"] = "item", ["desc"] = "奖励物品"}, ["key"] = {["id"] = "key", ["desc"] = "礼包id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "buy",
    },

    ["initdata"] = {
        desc = "初始化数据",
        log_format = {["dispatch_id"] = {["id"] = "dispatch_id", ["desc"] = "活动开启自增id"}, ["name"] = {["id"] = "name", ["desc"] = "活动名称"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案id"}},
        subtype = "initdata",
    },

    ["cleardata"] = {
        desc = "清除数据",
        log_format = {["dispatch_id"] = {["id"] = "dispatch_id", ["desc"] = "活动开启自增id"}, ["name"] = {["id"] = "name", ["desc"] = "活动名"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案id"}},
        subtype = "cleardata",
    },

    ["open"] = {
        desc = "活动开启",
        log_format = {["name"] = {["id"] = "name", ["desc"] = "活动名"}, ["open"] = {["id"] = "open", ["desc"] = "开启或关闭"}},
        subtype = "open",
    },

}
