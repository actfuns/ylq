-- ./excel/log/partner.xlsx
return {

    ["wuling_card"] = {
        desc = "普通抽卡",
        log_format = {["par"] = {["id"] = "par", ["desc"] = "伙伴类型"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "wuling_card",
    },

    ["wuhun_card"] = {
        desc = "高级抽卡",
        log_format = {["cost"] = {["id"] = "cost", ["desc"] = "花费水晶"}, ["item"] = {["id"] = "item", ["desc"] = "消耗的道具"}, ["par"] = {["id"] = "par", ["desc"] = "伙伴类型"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "wuhun_card",
    },

    ["exp"] = {
        desc = "获得经验",
        log_format = {["exp_add"] = {["id"] = "exp_add", ["desc"] = "增加经验"}, ["exp_now"] = {["id"] = "exp_now", ["desc"] = "当前经验"}, ["exp_old"] = {["id"] = "exp_old", ["desc"] = "原经验"}, ["parid"] = {["id"] = "parid", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["sid"] = {["id"] = "sid", ["desc"] = "伙伴sid"}},
        subtype = "exp",
    },

    ["grade"] = {
        desc = "伙伴升级",
        log_format = {["grade_now"] = {["id"] = "grade_now", ["desc"] = "当前等级"}, ["grade_old"] = {["id"] = "grade_old", ["desc"] = "原等级"}, ["parid"] = {["id"] = "parid", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["sid"] = {["id"] = "sid", ["desc"] = "伙伴sid"}},
        subtype = "grade",
    },

    ["add_partner"] = {
        desc = "获得伙伴",
        log_format = {["auto_skill"] = {["id"] = "auto_skill", ["desc"] = "自动选招"}, ["awake"] = {["id"] = "awake", ["desc"] = "觉醒"}, ["exp"] = {["id"] = "exp", ["desc"] = "经验"}, ["fight"] = {["id"] = "fight", ["desc"] = "上阵位置"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["lock"] = {["id"] = "lock", ["desc"] = "上锁"}, ["model"] = {["id"] = "model", ["desc"] = "模型信息"}, ["name"] = {["id"] = "name", ["desc"] = "名称"}, ["parid"] = {["id"] = "parid", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["rare"] = {["id"] = "rare", ["desc"] = "稀有度"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["sid"] = {["id"] = "sid", ["desc"] = "伙伴sid"}, ["skill"] = {["id"] = "skill", ["desc"] = "技能"}, ["star"] = {["id"] = "star", ["desc"] = "星级"}},
        subtype = "add_partner",
    },

    ["del_partner"] = {
        desc = "扣除伙伴",
        log_format = {["auto_skill"] = {["id"] = "auto_skill", ["desc"] = "自动选招"}, ["awake"] = {["id"] = "awake", ["desc"] = "觉醒"}, ["exp"] = {["id"] = "exp", ["desc"] = "经验"}, ["fight"] = {["id"] = "fight", ["desc"] = "上阵位置"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["lock"] = {["id"] = "lock", ["desc"] = "上锁"}, ["model"] = {["id"] = "model", ["desc"] = "模型信息"}, ["name"] = {["id"] = "name", ["desc"] = "名称"}, ["parid"] = {["id"] = "parid", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["rare"] = {["id"] = "rare", ["desc"] = "稀有度"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["sid"] = {["id"] = "sid", ["desc"] = "伙伴sid"}, ["skill"] = {["id"] = "skill", ["desc"] = "技能"}, ["star"] = {["id"] = "star", ["desc"] = "星级"}},
        subtype = "del_partner",
    },

    ["partner_fight"] = {
        desc = "伙伴上阵位置",
        log_format = {["parid"] = {["id"] = "parid", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["pos_now"] = {["id"] = "pos_now", ["desc"] = "当前位置"}, ["pos_old"] = {["id"] = "pos_old", ["desc"] = "原位置"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["sid"] = {["id"] = "sid", ["desc"] = "伙伴sid"}},
        subtype = "partner_fight",
    },

    ["awake_partner"] = {
        desc = "伙伴觉醒",
        log_format = {["awake_now"] = {["id"] = "awake_now", ["desc"] = "觉醒后"}, ["awake_old"] = {["id"] = "awake_old", ["desc"] = "觉醒前"}, ["parid"] = {["id"] = "parid", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["sid"] = {["id"] = "sid", ["desc"] = "伙伴sid"}},
        subtype = "awake_partner",
    },

    ["merge_partner"] = {
        desc = "合并伙伴",
        log_format = {["add"] = {["id"] = "add", ["desc"] = "合并数量"}, ["after"] = {["id"] = "after", ["desc"] = "合并后数量"}, ["destid"] = {["id"] = "destid", ["desc"] = "合并目标"}, ["partype"] = {["id"] = "partype", ["desc"] = "伙伴导表id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "操作"}, ["srcid"] = {["id"] = "srcid", ["desc"] = "被合并"}},
        subtype = "merge_partner",
    },

    ["open_parsoul"] = {
        desc = "开启御灵系统",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "open_parsoul",
    },

}
