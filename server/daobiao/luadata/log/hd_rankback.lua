-- ./excel/log/rankback.xlsx
return {

    ["open"] = {
        desc = "活动开启",
        log_format = {["name"] = {["id"] = "name", ["desc"] = "活动名"}, ["open"] = {["id"] = "open", ["desc"] = "开启或关闭"}},
        subtype = "open",
    },

    ["save"] = {
        desc = "保存数据",
        log_format = {["rank_idxs"] = {["id"] = "rank_idxs", ["desc"] = "排行榜id列表"}},
        subtype = "save",
    },

    ["save_count"] = {
        desc = "保存数量",
        log_format = {["count"] = {["id"] = "count", ["desc"] = "数量"}, ["status"] = {["id"] = "status", ["desc"] = "状态"}},
        subtype = "save_count",
    },

}
