-- ./excel/log/rank.xlsx
return {

    ["reset"] = {
        explain = "重置排行榜",
        log_format = {["idx"] = {["id"] = "idx", ["desc"] = "排行榜id"}, ["info"] = {["id"] = "info", ["desc"] = "排名信息"}, ["rank"] = {["id"] = "rank", ["desc"] = "排名"}, ["reason"] = {["id"] = "reason", ["desc"] = "操作"}, ["sub_key"] = {["id"] = "sub_key", ["desc"] = "多榜id"}, ["target"] = {["id"] = "target", ["desc"] = "目标id"}},
        subtype = "reset",
    },

    ["refresh"] = {
        explain = "刷榜",
        log_format = {["idx"] = {["id"] = "idx", ["desc"] = "排行榜id"}, ["info"] = {["id"] = "info", ["desc"] = "排名信息"}, ["rank"] = {["id"] = "rank", ["desc"] = "排名"}, ["reason"] = {["id"] = "reason", ["desc"] = "操作"}, ["sub_key"] = {["id"] = "sub_key", ["desc"] = "多榜id"}, ["target"] = {["id"] = "target", ["desc"] = "目标id"}},
        subtype = "refresh",
    },

    ["rushrank_send"] = {
        explain = "冲榜发奖",
        log_format = {["idx"] = {["id"] = "idx", ["desc"] = "排行榜id"}, ["reason"] = {["id"] = "reason", ["desc"] = "操作"}},
        subtype = "rushrank_send",
    },

    ["rushrank_reward"] = {
        explain = "冲榜奖励",
        log_format = {["idx"] = {["id"] = "idx", ["desc"] = "排行榜id"}, ["rank"] = {["id"] = "rank", ["desc"] = "排名"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励信息"}, ["sub_key"] = {["id"] = "sub_key", ["desc"] = "多榜id"}, ["target"] = {["id"] = "target", ["desc"] = "目标id"}, ["title"] = {["id"] = "title", ["desc"] = "称谓"}},
        subtype = "rushrank_reward",
    },

}
