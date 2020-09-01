-- ./excel/log/skill.xlsx
return {

    ["skill_point"] = {
        desc = "角色技能点",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "数量(负数为消耗)"}, ["branch"] = {["id"] = "branch", ["desc"] = "流派分支"}, ["now"] = {["id"] = "now", ["desc"] = "当前数量"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["reason"] = {["id"] = "reason", ["desc"] = "理由"}},
        subtype = "skill_point",
    },

    ["role_skill"] = {
        desc = "角色技能",
        log_format = {["after_level"] = {["id"] = "after_level", ["desc"] = "操作后等级"}, ["before_level"] = {["id"] = "before_level", ["desc"] = "操作前等级"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["reason"] = {["id"] = "reason", ["desc"] = "理由"}, ["skill_id"] = {["id"] = "skill_id", ["desc"] = "技能导表id"}},
        subtype = "role_skill",
    },

    ["cultivate_skill"] = {
        desc = "修炼技能",
        log_format = {["after_exp"] = {["id"] = "after_exp", ["desc"] = "操作后"}, ["after_level"] = {["id"] = "after_level", ["desc"] = "操作后等级"}, ["before_exp"] = {["id"] = "before_exp", ["desc"] = "操作前"}, ["before_level"] = {["id"] = "before_level", ["desc"] = "操作前等级"}, ["count"] = {["id"] = "count", ["desc"] = "修炼次数"}, ["critical"] = {["id"] = "critical", ["desc"] = "暴击次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["reason"] = {["id"] = "reason", ["desc"] = "理由"}, ["skill_id"] = {["id"] = "skill_id", ["desc"] = "技能导表id"}},
        subtype = "cultivate_skill",
    },

}
