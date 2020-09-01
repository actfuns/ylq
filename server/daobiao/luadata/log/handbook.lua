-- ./excel/log/handbook.xlsx
return {

    ["read_chapter"] = {
        desc = "读取章节",
        log_format = {["chapter_id"] = {["id"] = "chapter_id", ["desc"] = "章节id"}, ["is_read"] = {["id"] = "is_read", ["desc"] = "读取"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "read_chapter",
    },

    ["add_reward"] = {
        desc = "图鉴奖励",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "操作原因"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励信息"}},
        subtype = "add_reward",
    },

}
