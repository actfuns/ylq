-- ./excel/log/treasure.xlsx
return {

    ["init_mapinfo"] = {
        desc = "宝图坐标生成",
        log_format = {["itemid"] = {["id"] = "itemid", ["desc"] = "宝图道具ID"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["posinfo"] = {["id"] = "posinfo", ["desc"] = "宝图坐标信息"}},
        subtype = "init_mapinfo",
    },

    ["find_treasure"] = {
        desc = "挖宝",
        log_format = {["itemid"] = {["id"] = "itemid", ["desc"] = "宝图道具ID"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["posinfo"] = {["id"] = "posinfo", ["desc"] = "挖宝坐标信息"}, ["rewardinfo"] = {["id"] = "rewardinfo", ["desc"] = "触发事件信息"}, ["times"] = {["id"] = "times", ["desc"] = "挖宝次数"}},
        subtype = "find_treasure",
    },

    ["playerboy_changepos"] = {
        desc = "贪玩童子宝箱位置随机",
        log_format = {["newinfo"] = {["id"] = "newinfo", ["desc"] = "改变位置后的奖励信息"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "npcid"}, ["oldinfo"] = {["id"] = "oldinfo", ["desc"] = "改变位置前的奖励信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}},
        subtype = "playerboy_changepos",
    },

    ["playerboy_getreward"] = {
        desc = "贪玩童子开箱",
        log_format = {["index"] = {["id"] = "index", ["desc"] = "开箱位置"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "npcid"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["rewardidx"] = {["id"] = "rewardidx", ["desc"] = "获得物品"}, ["times"] = {["id"] = "times", ["desc"] = "开箱次数"}},
        subtype = "playerboy_getreward",
    },

    ["trigger_playerboy"] = {
        desc = "触发贪玩童子",
        log_format = {["itemid"] = {["id"] = "itemid", ["desc"] = "宝图道具ID"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "npcid"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["posinfo"] = {["id"] = "posinfo", ["desc"] = "贪玩童子坐标信息"}},
        subtype = "trigger_playerboy",
    },

    ["trigger_legendboy"] = {
        desc = "触发传说伙伴",
        log_format = {["itemid"] = {["id"] = "itemid", ["desc"] = "宝图道具ID"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "npcid"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["posinfo"] = {["id"] = "posinfo", ["desc"] = "贪玩童子坐标信息"}},
        subtype = "trigger_legendboy",
    },

    ["legendboy_enter"] = {
        desc = "进入传说伙伴副本",
        log_format = {["enterplayer"] = {["id"] = "enterplayer", ["desc"] = "进入的玩家"}, ["gameid"] = {["id"] = "gameid", ["desc"] = "猜拳副本游戏id"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "npcid"}},
        subtype = "legendboy_enter",
    },

    ["caiquan_gamestart"] = {
        desc = "猜拳游戏开始",
        log_format = {["gameid"] = {["id"] = "gameid", ["desc"] = "游戏ID"}, ["npcid_list"] = {["id"] = "npcid_list", ["desc"] = "npcid列表"}, ["player"] = {["id"] = "player", ["desc"] = "参与游戏玩家"}, ["sceneid"] = {["id"] = "sceneid", ["desc"] = "副本场景id"}},
        subtype = "caiquan_gamestart",
    },

    ["caiquan_gameend"] = {
        desc = "猜拳游戏结束",
        log_format = {["gameid"] = {["id"] = "gameid", ["desc"] = "游戏ID"}, ["player"] = {["id"] = "player", ["desc"] = "参与游戏玩家"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["result"] = {["id"] = "result", ["desc"] = "游戏结果"}, ["sceneid"] = {["id"] = "sceneid", ["desc"] = "副本场景id"}},
        subtype = "caiquan_gameend",
    },

    ["caiquannpc_event"] = {
        desc = "猜拳npc事件（挑战，胜利，失败，平局及双方出拳信息）",
        log_format = {["event"] = {["id"] = "event", ["desc"] = "事件"}, ["gameid"] = {["id"] = "gameid", ["desc"] = "游戏ID"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "npcid"}, ["pid"] = {["id"] = "pid", ["desc"] = "参与游戏玩家"}, ["times"] = {["id"] = "times", ["desc"] = "次数"}},
        subtype = "caiquannpc_event",
    },

    ["caiquan_reward"] = {
        desc = "获得猜拳奖励",
        log_format = {["gameid"] = {["id"] = "gameid", ["desc"] = "游戏ID"}, ["pid"] = {["id"] = "pid", ["desc"] = "领奖玩家"}, ["playertype"] = {["id"] = "playertype", ["desc"] = "玩家类型"}, ["rewardidx"] = {["id"] = "rewardidx", ["desc"] = "奖励id"}, ["times"] = {["id"] = "times", ["desc"] = "次数"}},
        subtype = "caiquan_reward",
    },

}
