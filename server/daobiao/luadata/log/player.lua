-- ./excel/log/player.xlsx
return {

    ["login"] = {
        desc = "登录日志",
        log_format = {["account"] = {["id"] = "account", ["desc"] = "账号"}, ["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["device"] = {["id"] = "device", ["desc"] = "设备号"}, ["fd"] = {["id"] = "fd", ["desc"] = "连接号"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["ip"] = {["id"] = "ip", ["desc"] = "ip地址"}, ["mac"] = {["id"] = "mac", ["desc"] = "mac地址"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}, ["reenter"] = {["id"] = "reenter", ["desc"] = "顶号"}},
        subtype = "login",
    },

    ["logout"] = {
        desc = "登出日志",
        log_format = {["account"] = {["id"] = "account", ["desc"] = "账号"}, ["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["duration"] = {["id"] = "duration", ["desc"] = "在线时长"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}},
        subtype = "logout",
    },

    ["newrole"] = {
        desc = "创角日志",
        log_format = {["account"] = {["id"] = "account", ["desc"] = "账号"}, ["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}, ["school"] = {["id"] = "school", ["desc"] = "门派"}, ["shape"] = {["id"] = "shape", ["desc"] = "造型"}},
        subtype = "newrole",
    },

    ["newday"] = {
        desc = "刷天日志",
        log_format = {["account"] = {["id"] = "account", ["desc"] = "账号"}, ["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["duration"] = {["id"] = "duration", ["desc"] = "在线时长"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}},
        subtype = "newday",
    },

    ["upgrade"] = {
        desc = "升级日志",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}, ["school"] = {["id"] = "school", ["desc"] = "门派"}},
        subtype = "upgrade",
    },

    ["switch_branch"] = {
        desc = "流派切换",
        log_format = {["branch"] = {["id"] = "branch", ["desc"] = "流派"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["school"] = {["id"] = "school", ["desc"] = "职业"}, ["weapon_sid"] = {["id"] = "weapon_sid", ["desc"] = "流派武器sid"}, ["weapon_trace"] = {["id"] = "weapon_trace", ["desc"] = "武器流水id"}},
        subtype = "switch_branch",
    },

    ["rename"] = {
        desc = "玩家改名",
        log_format = {["new_name"] = {["id"] = "new_name", ["desc"] = "新名字"}, ["old_name"] = {["id"] = "old_name", ["desc"] = "旧名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "rename",
    },

    ["addshape"] = {
        desc = "添加皮肤",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["shape"] = {["id"] = "shape", ["desc"] = "皮肤id"}},
        subtype = "addshape",
    },

    ["changeshape"] = {
        desc = "切换皮肤",
        log_format = {["new"] = {["id"] = "new", ["desc"] = "新皮肤"}, ["old"] = {["id"] = "old", ["desc"] = "旧皮肤"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "changeshape",
    },

    ["redeemcode"] = {
        desc = "礼包兑换",
        log_format = {["code"] = {["id"] = "code", ["desc"] = "兑换码"}, ["gift"] = {["id"] = "gift", ["desc"] = "礼包"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "redeemcode",
    },

}
