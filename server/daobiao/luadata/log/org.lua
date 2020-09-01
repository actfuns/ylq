-- ./excel/log/org.xlsx
return {

    ["create"] = {
        desc = "创建工会",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "create",
    },

    ["join"] = {
        desc = "加入工会",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "join",
    },

    ["apply"] = {
        desc = "申请加入工会",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "apply",
    },

    ["dealapply"] = {
        desc = "处理申请",
        log_format = {["deal"] = {["id"] = "deal", ["desc"] = "处理"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["target"] = {["id"] = "target", ["desc"] = "目标"}},
        subtype = "dealapply",
    },

    ["dealallapply"] = {
        desc = "拒绝所有申请",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "dealallapply",
    },

    ["dealinvite"] = {
        desc = "处理邀请",
        log_format = {["flag"] = {["id"] = "flag", ["desc"] = "同意与否"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "dealinvite",
    },

    ["invite"] = {
        desc = "邀请加入工会",
        log_format = {["inviteid"] = {["id"] = "inviteid", ["desc"] = "邀请id"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "invite",
    },

    ["kick"] = {
        desc = "踢出工会",
        log_format = {["kickid"] = {["id"] = "kickid", ["desc"] = "踢出id"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "kick",
    },

    ["leave"] = {
        desc = "离开工会",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "leave",
    },

    ["setpos"] = {
        desc = "安排职位",
        log_format = {["newp"] = {["id"] = "newp", ["desc"] = "新职位"}, ["oldp"] = {["id"] = "oldp", ["desc"] = "旧职位"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["target"] = {["id"] = "target", ["desc"] = "目标"}},
        subtype = "setpos",
    },

    ["setlimit"] = {
        desc = "设置工会现在",
        log_format = {["allow"] = {["id"] = "allow", ["desc"] = "是否审批"}, ["limit"] = {["id"] = "limit", ["desc"] = "战力限制"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "setlimit",
    },

    ["updateflag"] = {
        desc = "更新标志",
        log_format = {["flagbgid"] = {["id"] = "flagbgid", ["desc"] = "背景标志"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["sflag"] = {["id"] = "sflag", ["desc"] = "标志"}},
        subtype = "updateflag",
    },

    ["orgbuild"] = {
        desc = "工会建设",
        log_format = {["build_name"] = {["id"] = "build_name", ["desc"] = "建筑名称"}, ["build_type"] = {["id"] = "build_type", ["desc"] = "建筑类型"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "orgbuild",
    },

    ["speedbuild"] = {
        desc = "加速工会建设",
        log_format = {["goldcoin"] = {["id"] = "goldcoin", ["desc"] = "水晶"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "speedbuild",
    },

    ["build_done"] = {
        desc = "完成工会建设",
        log_format = {["build_type"] = {["id"] = "build_type", ["desc"] = "建筑类型"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "build_done",
    },

    ["orgsignreward"] = {
        desc = "领取签到奖励",
        log_format = {["idx"] = {["id"] = "idx", ["desc"] = "签到奖励项"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "orgsignreward",
    },

    ["orgwish"] = {
        desc = "工会许愿",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["partner_chip"] = {["id"] = "partner_chip", ["desc"] = "伙伴碎片"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "orgwish",
    },

    ["givewish"] = {
        desc = "帮助工会许愿",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["partner_chip"] = {["id"] = "partner_chip", ["desc"] = "伙伴碎片"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["target"] = {["id"] = "target", ["desc"] = "目标"}},
        subtype = "givewish",
    },

    ["openredpacket"] = {
        desc = "开启红包玩法",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["position"] = {["id"] = "position", ["desc"] = "职位"}},
        subtype = "openredpacket",
    },

    ["drawredpacket"] = {
        desc = "领取红包",
        log_format = {["idx"] = {["id"] = "idx", ["desc"] = "红包编号"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "drawredpacket",
    },

    ["uplevel"] = {
        desc = "工会升级",
        log_format = {["new_level"] = {["id"] = "new_level", ["desc"] = "等级"}, ["old_level"] = {["id"] = "old_level", ["desc"] = "以前等级"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "uplevel",
    },

    ["downlevel"] = {
        desc = "工会降级",
        log_format = {["new_level"] = {["id"] = "new_level", ["desc"] = "等级"}, ["old_level"] = {["id"] = "old_level", ["desc"] = "以前等级"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}},
        subtype = "downlevel",
    },

    ["release"] = {
        desc = "工会解散",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}},
        subtype = "release",
    },

    ["resumecash"] = {
        desc = "消耗工会资金",
        log_format = {["cash"] = {["id"] = "cash", ["desc"] = "公会资金"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["val"] = {["id"] = "val", ["desc"] = "消耗公会资金数目"}},
        subtype = "resumecash",
    },

    ["addcash"] = {
        desc = "获得工会资金",
        log_format = {["cash"] = {["id"] = "cash", ["desc"] = "公会资金"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["val"] = {["id"] = "val", ["desc"] = "获得公会资金数目"}},
        subtype = "addcash",
    },

    ["resumeexp"] = {
        desc = "消耗工会经验",
        log_format = {["exp"] = {["id"] = "exp", ["desc"] = "公会经验"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["val"] = {["id"] = "val", ["desc"] = "经验值"}},
        subtype = "resumeexp",
    },

    ["addexp"] = {
        desc = "获得工会经验",
        log_format = {["exp"] = {["id"] = "exp", ["desc"] = "公会经验"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["val"] = {["id"] = "val", ["desc"] = "经验值"}},
        subtype = "addexp",
    },

    ["equipwish"] = {
        desc = "装备许愿",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "工会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["sid"] = {["id"] = "sid", ["desc"] = "武器编号"}},
        subtype = "equipwish",
    },

    ["giveequipwish"] = {
        desc = "帮助装备许愿",
        log_format = {["orgid"] = {["id"] = "orgid", ["desc"] = "工会id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["sid"] = {["id"] = "sid", ["desc"] = "武器编号"}, ["target"] = {["id"] = "target", ["desc"] = "目标"}},
        subtype = "giveequipwish",
    },

    ["addprestige"] = {
        desc = "公会声望",
        log_format = {["add"] = {["id"] = "add", ["desc"] = "值"}, ["now"] = {["id"] = "now", ["desc"] = "当前值"}, ["orgid"] = {["id"] = "orgid", ["desc"] = "公会"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "addprestige",
    },

}
