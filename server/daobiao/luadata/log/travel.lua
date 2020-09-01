-- ./excel/log/travel.xlsx
return {

    ["travel_start"] = {
        desc = "开始游历",
        log_format = {["gap_second"] = {["id"] = "gap_second", ["desc"] = "奖励间隔"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["travel_second"] = {["id"] = "travel_second", ["desc"] = "游历时长"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "travel_start",
    },

    ["travel_stop"] = {
        desc = "停止游历",
        log_format = {["gap_second"] = {["id"] = "gap_second", ["desc"] = "奖励间隔"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["travel_second"] = {["id"] = "travel_second", ["desc"] = "游历时长"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "travel_stop",
    },

    ["friend_travel_mine"] = {
        desc = "好友寄存",
        log_format = {["friend_pid"] = {["id"] = "friend_pid", ["desc"] = "寄存好友pid"}, ["partnerid"] = {["id"] = "partnerid", ["desc"] = "寄存伙伴的id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "friend_travel_mine",
    },

    ["mine_travel_friend"] = {
        desc = "我寄存",
        log_format = {["friend_pid"] = {["id"] = "friend_pid", ["desc"] = "寄存好友pid"}, ["partnerid"] = {["id"] = "partnerid", ["desc"] = "寄存伙伴的id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "mine_travel_friend",
    },

    ["add_travel_reward"] = {
        desc = "奖励道具",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "获得数量"}, ["partnerid"] = {["id"] = "partnerid", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["pos"] = {["id"] = "pos", ["desc"] = "伙伴位置"}, ["reward_count"] = {["id"] = "reward_count", ["desc"] = "奖励次数"}, ["sid"] = {["id"] = "sid", ["desc"] = "道具id"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "add_travel_reward",
    },

    ["add_travel_exp"] = {
        desc = "奖励经验",
        log_format = {["partner_exp"] = {["id"] = "partner_exp", ["desc"] = "获得经验"}, ["partnerid"] = {["id"] = "partnerid", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["pos"] = {["id"] = "pos", ["desc"] = "伙伴位置"}, ["reward_count"] = {["id"] = "reward_count", ["desc"] = "奖励次数"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "add_travel_exp",
    },

    ["receive_travel_reward"] = {
        desc = "领取奖励",
        log_format = {["iteminfo"] = {["id"] = "iteminfo", ["desc"] = "奖励详情"}, ["partner_exp"] = {["id"] = "partner_exp", ["desc"] = "伙伴经验详情"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "receive_travel_reward",
    },

    ["receive_friend_reward"] = {
        desc = "领取寄存伙伴奖励",
        log_format = {["friend_pid"] = {["id"] = "friend_pid", ["desc"] = "寄存好友pid"}, ["partner_exp"] = {["id"] = "partner_exp", ["desc"] = "经验信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "receive_friend_reward",
    },

    ["trigger_draw_card"] = {
        desc = "触发翻牌",
        log_format = {["end_second"] = {["id"] = "end_second", ["desc"] = "结束时长"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "trigger_draw_card",
    },

    ["remove_draw_card"] = {
        desc = "移除翻牌",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["play_count"] = {["id"] = "play_count", ["desc"] = "翻牌玩法次数"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "remove_draw_card",
    },

    ["draw_card_start"] = {
        desc = "开启一轮翻牌",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["play_count"] = {["id"] = "play_count", ["desc"] = "翻牌玩法次数"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "draw_card_start",
    },

    ["draw_card_stop"] = {
        desc = "结束一轮翻牌",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["play_count"] = {["id"] = "play_count", ["desc"] = "翻牌玩法次数"}, ["travel_type"] = {["id"] = "travel_type", ["desc"] = "游历类型"}},
        subtype = "draw_card_stop",
    },

}
