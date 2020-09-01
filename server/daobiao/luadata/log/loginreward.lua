-- ./excel/log/loginreward.xlsx
return {

    ["login_day"] = {
        desc = "登录累计天数",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "角色名"}, ["now_login_day"] = {["id"] = "now_login_day", ["desc"] = "当前天数"}, ["old_login_day"] = {["id"] = "old_login_day", ["desc"] = "原天数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}},
        subtype = "login_day",
    },

    ["attach_reward"] = {
        desc = "领取登录奖励",
        log_format = {["attach_day"] = {["id"] = "attach_day", ["desc"] = "领取该天奖励"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["login_day"] = {["id"] = "login_day", ["desc"] = "登录天数"}, ["name"] = {["id"] = "name", ["desc"] = "角色名"}, ["now_reward_day"] = {["id"] = "now_reward_day", ["desc"] = "当前领奖天数信息"}, ["old_reward_day"] = {["id"] = "old_reward_day", ["desc"] = "原领奖天数信息"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "attach_reward",
    },

}
