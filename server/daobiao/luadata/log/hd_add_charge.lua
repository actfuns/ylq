-- ./excel/log/addcharge.xlsx
return {

    ["initdata"] = {
        desc = "初始化数据",
        log_format = {["dispatch_id"] = {["id"] = "dispatch_id", ["desc"] = "活动开启自增id"}, ["idx"] = {["id"] = "idx", ["desc"] = "活动id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案id"}},
        subtype = "initdata",
    },

    ["cleardata"] = {
        desc = "清除数据",
        log_format = {["dispatch_id"] = {["id"] = "dispatch_id", ["desc"] = "活动开启自增id"}, ["idx"] = {["id"] = "idx", ["desc"] = "活动id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案id"}},
        subtype = "cleardata",
    },

    ["add_progress"] = {
        desc = "充值进度",
        log_format = {["dispatch_id"] = {["id"] = "dispatch_id", ["desc"] = "活动开启自增id"}, ["idx"] = {["id"] = "idx", ["desc"] = "活动id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案id"}, ["progress"] = {["id"] = "progress", ["desc"] = "进度"}},
        subtype = "add_progress",
    },

    ["receive"] = {
        desc = "领取进度奖励",
        log_format = {["dispatch_id"] = {["id"] = "dispatch_id", ["desc"] = "活动开启自增id"}, ["idx"] = {["id"] = "idx", ["desc"] = "活动id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案id"}, ["progress"] = {["id"] = "progress", ["desc"] = "进度"}},
        subtype = "receive",
    },

}
