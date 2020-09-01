-- ./excel/log/house.xlsx
return {

    ["addpartner"] = {
        desc = "添加宅邸伙伴",
        log_format = {["partype"] = {["id"] = "partype", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "操作原因"}},
        subtype = "addpartner",
    },

    ["upgrade_furniture"] = {
        desc = "升级家具",
        log_format = {["level"] = {["id"] = "level", ["desc"] = "当前等级"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "upgrade_furniture",
    },

    ["upgrade_furniture_done"] = {
        desc = "升级家具完成",
        log_format = {["new_level"] = {["id"] = "new_level", ["desc"] = "当前等级"}, ["old_level"] = {["id"] = "old_level", ["desc"] = "原来等级"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "操作原因"}},
        subtype = "upgrade_furniture_done",
    },

    ["talent_show"] = {
        desc = "工作台才艺展示",
        log_format = {["end_time"] = {["id"] = "end_time", ["desc"] = "才艺结束时间"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["status"] = {["id"] = "status", ["desc"] = "工作台状态"}},
        subtype = "talent_show",
    },

    ["receive_talent_show"] = {
        desc = "领取工作台奖励",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励明细"}},
        subtype = "receive_talent_show",
    },

    ["help_workdesk"] = {
        desc = "帮助加速好友工作台",
        log_format = {["count"] = {["id"] = "count", ["desc"] = "当天帮助次数"}, ["frd_pid"] = {["id"] = "frd_pid", ["desc"] = "好友id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "help_workdesk",
    },

    ["use_friend_desk"] = {
        desc = "使用好友工作台",
        log_format = {["end_time"] = {["id"] = "end_time", ["desc"] = "结束时间"}, ["frd_pid"] = {["id"] = "frd_pid", ["desc"] = "好友id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "use_friend_desk",
    },

    ["daily_friend_desk"] = {
        desc = "使用工作台次数",
        log_format = {["count"] = {["id"] = "count", ["desc"] = "当天使用次数"}, ["frd_pid"] = {["id"] = "frd_pid", ["desc"] = "好友id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "daily_friend_desk",
    },

    ["friend_desk_reward"] = {
        desc = "好友工作奖励",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "数量"}, ["frd_pid"] = {["id"] = "frd_pid", ["desc"] = "好友id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["sid"] = {["id"] = "sid", ["desc"] = "道具id"}},
        subtype = "friend_desk_reward",
    },

    ["partnerexp"] = {
        desc = "增加宅邸伙伴经验",
        log_format = {["new_exp"] = {["id"] = "new_exp", ["desc"] = "当前经验"}, ["old_exp"] = {["id"] = "old_exp", ["desc"] = "原先经验"}, ["partype"] = {["id"] = "partype", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "partnerexp",
    },

    ["partner_level"] = {
        desc = "伙伴等级",
        log_format = {["new_level"] = {["id"] = "new_level", ["desc"] = "当前等级"}, ["old_level"] = {["id"] = "old_level", ["desc"] = "原来等级"}, ["partype"] = {["id"] = "partype", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "partner_level",
    },

    ["parlove_count"] = {
        desc = "伙伴爱抚次数",
        log_format = {["old_cnt"] = {["id"] = "old_cnt", ["desc"] = "原来次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["remain_cnt"] = {["id"] = "remain_cnt", ["desc"] = "剩余次数"}},
        subtype = "parlove_count",
    },

    ["give_partner_gift"] = {
        desc = "伙伴送礼",
        log_format = {["old_cnt"] = {["id"] = "old_cnt", ["desc"] = "原来次数"}, ["partype"] = {["id"] = "partype", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["remain_cnt"] = {["id"] = "remain_cnt", ["desc"] = "剩余次数"}, ["sid"] = {["id"] = "sid", ["desc"] = "道具导表id"}},
        subtype = "give_partner_gift",
    },

    ["partner_train_status"] = {
        desc = "伙伴特训",
        log_format = {["partype"] = {["id"] = "partype", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["status"] = {["id"] = "status", ["desc"] = "状态"}, ["train_end"] = {["id"] = "train_end", ["desc"] = "结束时间"}},
        subtype = "partner_train_status",
    },

    ["partner_level_reward"] = {
        desc = "伙伴等级奖励",
        log_format = {["level"] = {["id"] = "level", ["desc"] = "等级"}, ["partype"] = {["id"] = "partype", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励信息"}},
        subtype = "partner_level_reward",
    },

    ["receive_house_coin"] = {
        desc = "领取好友宅邸随机奖励",
        log_format = {["coin"] = {["id"] = "coin", ["desc"] = "金币数量"}, ["daily_cnt"] = {["id"] = "daily_cnt", ["desc"] = "每日次数"}, ["frd_pid"] = {["id"] = "frd_pid", ["desc"] = "好友id"}, ["partype"] = {["id"] = "partype", ["desc"] = "伙伴id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "receive_house_coin",
    },

    ["love_buff_stage"] = {
        desc = "宅邸buff阶级",
        log_format = {["now_stage"] = {["id"] = "now_stage", ["desc"] = "新阶级"}, ["old_stage"] = {["id"] = "old_stage", ["desc"] = "旧阶级"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "操作"}},
        subtype = "love_buff_stage",
    },

}
