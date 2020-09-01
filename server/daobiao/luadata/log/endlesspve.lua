-- ./excel/log/endlesspve.xlsx
return {

    ["chip_list"] = {
        desc = "刷出的碎片信息",
        log_format = {["chip_list"] = {["id"] = "chip_list", ["desc"] = "碎片信息"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "角色名"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "chip_list",
    },

    ["endless_start"] = {
        desc = "无尽pve战斗开启",
        log_format = {["chip_sid"] = {["id"] = "chip_sid", ["desc"] = "获得碎片id"}, ["fight_id"] = {["id"] = "fight_id", ["desc"] = "关卡id"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "角色名"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "endless_start",
    },

    ["endless_end"] = {
        desc = "无尽pve战斗关闭",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "角色名"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励id"}, ["reward_chip"] = {["id"] = "reward_chip", ["desc"] = "碎片奖励"}, ["ring"] = {["id"] = "ring", ["desc"] = "已通过战斗层数"}},
        subtype = "endless_end",
    },

}
