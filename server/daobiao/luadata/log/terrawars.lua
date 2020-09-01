-- ./excel/log/terrawars.xlsx
return {

    ["lingli_change"] = {
        desc = "灵力变化",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "变化数量"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "lingli_change",
    },

    ["add_attack"] = {
        desc = "加入进攻队列",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "add_attack",
    },

    ["cancel_attack"] = {
        desc = "取消进攻",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "cancel_attack",
    },

    ["add_help"] = {
        desc = "加入支援队列",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "add_help",
    },

    ["cancel_help"] = {
        desc = "取消支援",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "cancel_help",
    },

    ["attack_fail"] = {
        desc = "进攻战斗失败",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "attack_fail",
    },

    ["defend_fail"] = {
        desc = "支援战斗失败",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "defend_fail",
    },

    ["attack_success"] = {
        desc = "进攻占领成功",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "attack_success",
    },

    ["defend_success"] = {
        desc = "支援占领成功",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "defend_success",
    },

    ["set_guard"] = {
        desc = "设置驻守伙伴",
        log_format = {["guard_info"] = {["id"] = "guard_info", ["desc"] = "防守信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "set_guard",
    },

    ["giveup_terra"] = {
        desc = "放弃据点",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "giveup_terra",
    },

    ["addperpoints"] = {
        desc = "增加个人积分",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "变化数量"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "addperpoints",
    },

    ["addorgpoints"] = {
        desc = "增加工会积分",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "变化数量"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "工会ID"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "addorgpoints",
    },

    ["addpercontribution"] = {
        desc = "增加个人贡献度",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "变化数量"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["terraid"] = {["id"] = "terraid", ["desc"] = "据点ID"}},
        subtype = "addpercontribution",
    },

}
