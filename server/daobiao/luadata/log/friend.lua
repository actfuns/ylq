-- ./excel/log/friend.xlsx
return {

    ["addfriend"] = {
        desc = "添加好友",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["sum"] = {["id"] = "sum", ["desc"] = "好友总数"}, ["target"] = {["id"] = "target", ["desc"] = "目标"}},
        subtype = "addfriend",
    },

    ["delfriend"] = {
        desc = "删除好友",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["sum"] = {["id"] = "sum", ["desc"] = "好友总数"}, ["target"] = {["id"] = "target", ["desc"] = "目标"}},
        subtype = "delfriend",
    },

}
