-- ./excel/log/chat.xlsx
return {

    ["chat"] = {
        desc = "频道发言",
        log_format = {["channel"] = {["id"] = "channel", ["desc"] = "频道"}, ["name"] = {["id"] = "name", ["desc"] = "名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["svr"] = {["id"] = "svr", ["desc"] = "server_key"}, ["text"] = {["id"] = "text", ["desc"] = "内容"}},
        subtype = "chat",
    },

    ["friend"] = {
        desc = "好友聊天",
        log_format = {["name"] = {["id"] = "name", ["desc"] = "名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["svr"] = {["id"] = "svr", ["desc"] = "server_key"}, ["target"] = {["id"] = "target", ["desc"] = "接收方"}, ["targetname"] = {["id"] = "targetname", ["desc"] = "名字"}, ["text"] = {["id"] = "text", ["desc"] = "内容"}},
        subtype = "friend",
    },

    ["debug"] = {
        desc = "调试信息",
        log_format = {["op"] = {["id"] = "op", ["desc"] = "操作"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["plist"] = {["id"] = "plist", ["desc"] = "好友列表"}},
        subtype = "debug",
    },

}
