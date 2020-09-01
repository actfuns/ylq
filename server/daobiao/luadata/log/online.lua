-- ./excel/log/online.xlsx
return {

    ["online"] = {
        desc = "在线总人数",
        log_format = {["online_cnt"] = {["id"] = "online_cnt", ["desc"] = "在线人数"}},
        subtype = "online",
    },

    ["detail"] = {
        desc = "详细在线人数",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "渠道"}, ["online_cnt"] = {["id"] = "online_cnt", ["desc"] = "在线人数"}, ["platform"] = {["id"] = "platform", ["desc"] = "平台"}},
        subtype = "detail",
    },

}
