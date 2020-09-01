-- ./excel/log/analy.xlsx
return {

    ["newaccount"] = {
        desc = "注册信息",
        log_format = {["alist"] = {["id"] = "alist", ["desc"] = "账号列表"}, ["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}},
        subtype = "newaccount",
    },

    ["newrole"] = {
        desc = "创角信息",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}, ["plist"] = {["id"] = "plist", ["desc"] = "角色列表"}},
        subtype = "newrole",
    },

    ["newdevice"] = {
        desc = "新设备信息",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["mlist"] = {["id"] = "mlist", ["desc"] = "设备列表"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}},
        subtype = "newdevice",
    },

    ["loginact"] = {
        desc = "账号登录信息",
        log_format = {["alist"] = {["id"] = "alist", ["desc"] = "账号列表"}, ["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}},
        subtype = "loginact",
    },

    ["loginrole"] = {
        desc = "角色登录信息",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}, ["plist"] = {["id"] = "plist", ["desc"] = "角色列表"}},
        subtype = "loginrole",
    },

    ["logindev"] = {
        desc = "设备登录信息",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["mlist"] = {["id"] = "mlist", ["desc"] = "设备列表"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}},
        subtype = "logindev",
    },

    ["loginmodel"] = {
        desc = "机型登录信息",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["mlist"] = {["id"] = "mlist", ["desc"] = "机型列表"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}},
        subtype = "loginmodel",
    },

    ["online"] = {
        desc = "在线信息",
        log_format = {["avgcnt"] = {["id"] = "avgcnt", ["desc"] = "平均在线人数"}, ["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["interval"] = {["id"] = "interval", ["desc"] = "时段在线人数"}, ["maxcnt"] = {["id"] = "maxcnt", ["desc"] = "最大在线人数"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}},
        subtype = "online",
    },

    ["upgrade"] = {
        desc = "等级信息",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}, ["plist"] = {["id"] = "plist", ["desc"] = "角色信息列表"}},
        subtype = "upgrade",
    },

    ["duration"] = {
        desc = "在线时长信息",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}, ["plist"] = {["id"] = "plist", ["desc"] = "角色信息列表"}},
        subtype = "duration",
    },

    ["storytask"] = {
        desc = "主线任务信息",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}, ["plist"] = {["id"] = "plist", ["desc"] = "角色信息列表"}},
        subtype = "storytask",
    },

}
