-- ./excel/log/picture.xlsx
return {

    ["degree_change"] = {
        desc = "进度改变",
        log_format = {["id"] = {["id"] = "id", ["desc"] = "图鉴ID"}, ["key"] = {["id"] = "key", ["desc"] = "变化字段"}, ["new_degree"] = {["id"] = "new_degree", ["desc"] = "新进度"}, ["old_degree"] = {["id"] = "old_degree", ["desc"] = "旧进度"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["target"] = {["id"] = "target", ["desc"] = "变化目标"}},
        subtype = "degree_change",
    },

    ["reward"] = {
        desc = "领奖",
        log_format = {["degree"] = {["id"] = "degree", ["desc"] = "当前进度"}, ["id"] = {["id"] = "id", ["desc"] = "图鉴ID"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}},
        subtype = "reward",
    },

}
