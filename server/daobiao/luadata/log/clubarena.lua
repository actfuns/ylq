-- ./excel/log/clubarena.xlsx
return {

    ["reward_cluba"] = {
        desc = "馆主过天奖励 ",
        log_format = {["reward"] = {["id"] = "reward", ["desc"] = "玩家列表"}},
        subtype = "reward_cluba",
    },

    ["war_end"] = {
        desc = "战斗信息",
        log_format = {["club"] = {["id"] = "club", ["desc"] = "武馆"}, ["cur_club"] = {["id"] = "cur_club", ["desc"] = "武馆"}, ["cur_post"] = {["id"] = "cur_post", ["desc"] = "位置"}, ["cur_target_club"] = {["id"] = "cur_target_club", ["desc"] = "武馆"}, ["cur_target_post"] = {["id"] = "cur_target_post", ["desc"] = "位置"}, ["name"] = {["id"] = "name", ["desc"] = "名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["post"] = {["id"] = "post", ["desc"] = "位置(0为馆主)"}, ["target"] = {["id"] = "target", ["desc"] = "目标"}, ["target_club"] = {["id"] = "target_club", ["desc"] = "馆"}, ["target_post"] = {["id"] = "target_post", ["desc"] = "位置"}, ["targetname"] = {["id"] = "targetname", ["desc"] = "名字"}, ["win"] = {["id"] = "win", ["desc"] = "胜利"}},
        subtype = "war_end",
    },

}
