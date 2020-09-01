-- ./excel/log/schedule.xlsx
return {

    ["add_active"] = {
        desc = "日程-活跃 ",
        log_format = {["add"] = {["id"] = "add", ["desc"] = "增加活跃"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["point"] = {["id"] = "point", ["desc"] = "增加后积分"}, ["schedule"] = {["id"] = "schedule", ["desc"] = "日程"}},
        subtype = "add_active",
    },

    ["get_reward"] = {
        desc = "日程-奖励",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["idx"] = {["id"] = "idx", ["desc"] = "宝箱编号"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "get_reward",
    },

    ["schedule_change"] = {
        desc = "日程-进度 ",
        log_format = {["done"] = {["id"] = "done", ["desc"] = "当前完成次数"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["schedule"] = {["id"] = "schedule", ["desc"] = "完成日程ID"}},
        subtype = "schedule_change",
    },

    ["schedule_reset"] = {
        desc = "日程-重置",
        log_format = {["oldday"] = {["id"] = "oldday", ["desc"] = "旧日期"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["today"] = {["id"] = "today", ["desc"] = "新日期"}},
        subtype = "schedule_reset",
    },

}
