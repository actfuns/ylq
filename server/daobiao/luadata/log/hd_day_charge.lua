-- ./excel/log/daycharge.xlsx
return {

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

    ["add_progress"] = {
        desc = "充值进度",
        log_format = {["dispatch_id"] = {["id"] = "dispatch_id", ["desc"] = "活动开启自增id"}, ["name"] = {["id"] = "name", ["desc"] = "活动名"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案id"}, ["progress"] = {["id"] = "progress", ["desc"] = "进度"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "add_progress",
    },

    ["receive"] = {
        desc = "领取进度奖励",
        log_format = {["dispatch_id"] = {["id"] = "dispatch_id", ["desc"] = "活动开启自增id"}, ["id"] = {["id"] = "id", ["desc"] = "领取id"}, ["name"] = {["id"] = "name", ["desc"] = "活动名"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案id"}, ["progress"] = {["id"] = "progress", ["desc"] = "进度"}},
        subtype = "receive",
    },

    ["open"] = {
        desc = "活动开启",
        log_format = {["name"] = {["id"] = "name", ["desc"] = "活动名"}, ["open"] = {["id"] = "open", ["desc"] = "开启或关闭"}},
        subtype = "open",
    },

}
