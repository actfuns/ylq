-- ./excel/log/pefuben.xlsx
return {

    ["join"] = {
        desc = "异空流放-战斗结算",
        log_format = {["equip"] = {["id"] = "equip", ["desc"] = "锁定类型"}, ["part"] = {["id"] = "part", ["desc"] = "锁定部位"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["reward_item"] = {["id"] = "reward_item", ["desc"] = "奖励道具"}, ["start"] = {["id"] = "start", ["desc"] = "进入战斗时间"}, ["type"] = {["id"] = "type", ["desc"] = "副本类型"}, ["use"] = {["id"] = "use", ["desc"] = "使用次数"}},
        subtype = "join",
    },

    ["turn"] = {
        desc = "异空流放-转盘抽取部位和装备类型",
        log_format = {["cost"] = {["id"] = "cost", ["desc"] = "花费"}, ["equip"] = {["id"] = "equip", ["desc"] = "抽中类型"}, ["part"] = {["id"] = "part", ["desc"] = "抽中部位"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["type"] = {["id"] = "type", ["desc"] = "副本类型"}},
        subtype = "turn",
    },

    ["lock"] = {
        desc = "异空流放-锁定/解锁信息",
        log_format = {["lock"] = {["id"] = "lock", ["desc"] = "锁定（0解锁，1锁定部位，2锁定装备类型）"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["type"] = {["id"] = "type", ["desc"] = "副本"}},
        subtype = "lock",
    },

}
