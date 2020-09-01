-- ./excel/log/equipfuben.xlsx
return {

    ["join"] = {
        desc = "埋骨之地-通关记录",
        log_format = {["after_Star"] = {["id"] = "after_Star", ["desc"] = "结束后总星"}, ["befor_star"] = {["id"] = "befor_star", ["desc"] = "开始前总星"}, ["dead"] = {["id"] = "dead", ["desc"] = "死亡"}, ["first"] = {["id"] = "first", ["desc"] = "是否第一次通关"}, ["floor"] = {["id"] = "floor", ["desc"] = "通关层数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["remain"] = {["id"] = "remain", ["desc"] = "剩余可挑战次数"}, ["star"] = {["id"] = "star", ["desc"] = "评分"}, ["timeout"] = {["id"] = "timeout", ["desc"] = "超时"}, ["type"] = {["id"] = "type", ["desc"] = "副本类型"}, ["use"] = {["id"] = "use", ["desc"] = "已用次数"}},
        subtype = "join",
    },

    ["sweep_fail"] = {
        desc = "扫荡失败",
        log_format = {["count"] = {["id"] = "count", ["desc"] = "扫荡次数"}, ["floor"] = {["id"] = "floor", ["desc"] = "层数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["type"] = {["id"] = "type", ["desc"] = "副本类型"}},
        subtype = "sweep_fail",
    },

    ["sweep_success"] = {
        desc = "扫荡成功",
        log_format = {["count"] = {["id"] = "count", ["desc"] = "扫荡次数"}, ["floor"] = {["id"] = "floor", ["desc"] = "层数"}, ["item"] = {["id"] = "item", ["desc"] = "奖励道具"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["remain"] = {["id"] = "remain", ["desc"] = "剩余挑战次数"}, ["type"] = {["id"] = "type", ["desc"] = "副本类型"}},
        subtype = "sweep_success",
    },

}
