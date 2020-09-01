-- ./excel/log/item.xlsx
return {

    ["equip_strength"] = {
        desc = "装备突破",
        log_format = {["after_level"] = {["id"] = "after_level", ["desc"] = "操作后等级"}, ["before_level"] = {["id"] = "before_level", ["desc"] = "操作前等级"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["pos"] = {["id"] = "pos", ["desc"] = "部位"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "equip_strength",
    },

    ["add_fuwen_plan"] = {
        desc = "添加淬灵方案",
        log_format = {["fuwen"] = {["id"] = "fuwen", ["desc"] = "淬灵信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案"}, ["pos"] = {["id"] = "pos", ["desc"] = "部位"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "add_fuwen_plan",
    },

    ["use_fuwen_plan"] = {
        desc = "使用符文方案",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案"}, ["pos"] = {["id"] = "pos", ["desc"] = "部位"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "use_fuwen_plan",
    },

    ["new_fuwen"] = {
        desc = "洗点符文",
        log_format = {["back_fuwen"] = {["id"] = "back_fuwen", ["desc"] = "洗点符文"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案"}, ["pos"] = {["id"] = "pos", ["desc"] = "部位"}},
        subtype = "new_fuwen",
    },

    ["save_fuwen"] = {
        desc = "保存符文",
        log_format = {["now_fuwen"] = {["id"] = "now_fuwen", ["desc"] = "当前符文"}, ["old_fuwen"] = {["id"] = "old_fuwen", ["desc"] = "旧符文"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["plan"] = {["id"] = "plan", ["desc"] = "方案"}, ["pos"] = {["id"] = "pos", ["desc"] = "部位"}},
        subtype = "save_fuwen",
    },

    ["equip_gem"] = {
        desc = "装备宝石",
        log_format = {["after_exp"] = {["id"] = "after_exp", ["desc"] = "操作后经验"}, ["before_exp"] = {["id"] = "before_exp", ["desc"] = "操作前经验"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["pos"] = {["id"] = "pos", ["desc"] = "部位"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "equip_gem",
    },

    ["second_equip"] = {
        desc = "获得另一流派装备",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["pos"] = {["id"] = "pos", ["desc"] = "部位"}, ["sid"] = {["id"] = "sid", ["desc"] = "道具sid"}, ["trace"] = {["id"] = "trace", ["desc"] = "道具流水id"}},
        subtype = "second_equip",
    },

}
